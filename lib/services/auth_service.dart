import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../config/firebase_config.dart';

/// Authentication service for Dostok.
///
/// On first launch the user is signed in anonymously so the app is usable
/// immediately. Account linking (Google / Apple) is offered later as an
/// optional upgrade so progress survives device changes.
///
/// All public methods are safe to call when offline -- Firebase Auth caches
/// credentials locally and reconciles on reconnect.
///
/// In demo mode (no .env / no Firebase), all methods are no-ops and a
/// hardcoded demo UID is used.
class AuthService {
  AuthService({FirebaseAuth? auth})
      : _isDemo = FirebaseConfig.isDemoMode || Firebase.apps.isEmpty,
        _auth = auth ?? (FirebaseConfig.isDemoMode || Firebase.apps.isEmpty
            ? null
            : FirebaseAuth.instance);

  final FirebaseAuth? _auth;
  final bool _isDemo;

  /// Demo-mode UID used when Firebase is unavailable.
  static const String demoUid = 'demo-user-local';

  // ---------------------------------------------------------------------------
  // Streams & getters
  // ---------------------------------------------------------------------------

  /// Fires on every auth state change (sign-in, sign-out, token refresh).
  Stream<User?> get currentUser {
    if (_isDemo) return Stream.value(null);
    return _auth!.authStateChanges();
  }

  /// Current user or `null`.
  User? get user => _isDemo ? null : _auth!.currentUser;

  /// Convenience UID accessor. Returns `null` when not signed in.
  String? get uid => _isDemo ? demoUid : _auth!.currentUser?.uid;

  /// Whether an account is currently signed in.
  bool get isAuthenticated => _isDemo ? true : _auth!.currentUser != null;

  /// Whether the current account is still anonymous (not linked).
  bool get isAnonymous => _isDemo ? true : _auth!.currentUser?.isAnonymous ?? true;

  // ---------------------------------------------------------------------------
  // Sign in
  // ---------------------------------------------------------------------------

  /// Sign in anonymously. Called on first launch so the user can start
  /// using the app immediately without providing credentials.
  ///
  /// Returns the [UserCredential] on success, `null` on failure.
  Future<UserCredential?> signInAnonymously() async {
    if (_isDemo) {
      if (kDebugMode) {
        debugPrint('[AuthService] Demo mode — skipping sign-in');
      }
      return null;
    }
    try {
      final credential = await _auth!.signInAnonymously();
      if (kDebugMode) {
        debugPrint('[AuthService] Signed in anonymously: ${credential.user?.uid}');
      }
      return credential;
    } on FirebaseAuthException catch (e) {
      _logError('signInAnonymously', e);
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Account linking
  // ---------------------------------------------------------------------------

  /// Link the current anonymous account with Google.
  ///
  /// If the Google credential is already associated with a *different* account,
  /// we sign into that existing account instead and return it -- the anonymous
  /// data is then lost (caller should migrate if needed).
  Future<UserCredential?> linkWithGoogle() async {
    if (_isDemo) return null;
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null; // user cancelled

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _linkOrSignIn(credential);
    } on FirebaseAuthException catch (e) {
      _logError('linkWithGoogle', e);
      rethrow;
    } catch (e) {
      _logError('linkWithGoogle (unexpected)', e);
      return null;
    }
  }

  /// Link the current anonymous account with Apple.
  ///
  /// Available on iOS 13+ and macOS 10.15+. Returns `null` on unsupported
  /// platforms or when the user cancels.
  Future<UserCredential?> linkWithApple() async {
    if (_isDemo) return null;
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      return await _linkOrSignIn(oauthCredential);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      _logError('linkWithApple', e);
      return null;
    } on FirebaseAuthException catch (e) {
      _logError('linkWithApple', e);
      rethrow;
    } catch (e) {
      _logError('linkWithApple (unexpected)', e);
      return null;
    }
  }

  /// Attempts to link [credential] to the current anonymous user.
  ///
  /// If the credential is already in use by another account (error
  /// `provider-already-linked` or `credential-already-in-use`), we sign in
  /// with that credential instead so the user is not blocked.
  Future<UserCredential?> _linkOrSignIn(AuthCredential credential) async {
    final currentUser = _auth!.currentUser;
    if (currentUser == null) return null;

    try {
      // Try linking first.
      final result = await currentUser.linkWithCredential(credential);
      if (kDebugMode) {
        debugPrint('[AuthService] Linked account: ${result.user?.uid}');
      }
      return result;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'provider-already-linked') {
        // Already linked to this provider on this account -- just refresh.
        return await currentUser.reauthenticateWithCredential(credential);
      }
      if (e.code == 'credential-already-in-use' ||
          e.code == 'email-already-in-use') {
        // The credential belongs to a different account. Sign into that one.
        if (kDebugMode) {
          debugPrint('[AuthService] Credential in use -- signing into existing account');
        }
        return await _auth!.signInWithCredential(credential);
      }
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Sign out
  // ---------------------------------------------------------------------------

  /// Sign out the current user.
  ///
  /// Returns `true` on success. Callers should show a confirmation dialog
  /// before invoking this.
  Future<bool> signOut() async {
    if (_isDemo) return true;
    try {
      // Also sign out of Google if applicable.
      await GoogleSignIn().signOut().catchError((_) => null);
      await _auth!.signOut();
      if (kDebugMode) {
        debugPrint('[AuthService] Signed out');
      }
      return true;
    } catch (e) {
      _logError('signOut', e);
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Account deletion (GDPR)
  // ---------------------------------------------------------------------------

  /// Permanently delete the current user's account and all associated data.
  ///
  /// GDPR compliance notes:
  ///   - The caller MUST obtain explicit confirmation before calling this.
  ///   - Firestore data should be deleted by a Cloud Function triggered on
  ///     `auth.user().onDelete()` so that server-side data is also purged.
  ///   - Returns `true` on success, `false` on failure.
  ///
  /// If the user recently signed in (within 5 minutes) the re-authentication
  /// step may be skipped. Otherwise the caller should prompt for credentials
  /// and pass them via [reauthCredential].
  Future<bool> deleteAccount({AuthCredential? reauthCredential}) async {
    if (_isDemo) return true;
    try {
      final currentUser = _auth!.currentUser;
      if (currentUser == null) return false;

      // Re-authenticate if a credential is provided (required for sensitive ops
      // when the session is older than 5 minutes).
      if (reauthCredential != null) {
        await currentUser.reauthenticateWithCredential(reauthCredential);
      }

      await currentUser.delete();
      if (kDebugMode) {
        debugPrint('[AuthService] Account deleted');
      }
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        // Caller must re-authenticate and retry.
        _logError('deleteAccount -- requires recent login', e);
        rethrow;
      }
      _logError('deleteAccount', e);
      return false;
    } catch (e) {
      _logError('deleteAccount (unexpected)', e);
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _logError(String method, Object error) {
    if (kDebugMode) {
      debugPrint('[AuthService] $method error: $error');
    }
  }
}
