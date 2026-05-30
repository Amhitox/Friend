import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Firebase configuration for the Dostok app.
///
/// Supports environment-based configuration (dev/staging/prod).
/// Users must fill in their own Firebase project credentials.
///
/// Create a `.env` file at the project root with:
///   FIREBASE_ENV=dev
///   FIREBASE_API_KEY_ANDROID=your_key
///   FIREBASE_APP_ID_ANDROID=your_app_id
///   FIREBASE_MESSAGING_SENDER_ID=your_sender_id
///   FIREBASE_PROJECT_ID=your_project_id
///   FIREBASE_API_KEY_IOS=your_key
///   FIREBASE_APP_ID_IOS=your_app_id
///   FIREBASE_IOS_BUNDLE_ID=com.your.bundle
///   FIREBASE_STORAGE_BUCKET=your_bucket
class FirebaseConfig {
  static bool _initialized = false;

  /// Current environment derived from `FIREBASE_ENV` env variable.
  /// Falls back to `dev` when not set.
  static String get environment =>
      dotenv.env['FIREBASE_ENV'] ?? 'dev';

  static bool get isProduction => environment == 'prod';
  static bool get isStaging => environment == 'staging';
  static bool get isDevelopment => environment == 'dev';

  /// Initialize Firebase with platform-specific options.
  ///
  /// Safe to call multiple times -- subsequent calls are no-ops.
  /// Loads `.env` first so all env variables are available.
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      await dotenv.load(fileName: '.env');

      final options = _resolveOptions();

      await Firebase.initializeApp(options: options);
      _initialized = true;

      if (kDebugMode) {
        debugPrint('[FirebaseConfig] Initialized for environment: $environment');
      }
    } on FirebaseException catch (e) {
      // Already initialized (hot restart, tests) -- swallow.
      if (e.code == 'duplicate-app') {
        _initialized = true;
        return;
      }
      rethrow;
    } catch (e, st) {
      debugPrint('[FirebaseConfig] Initialization failed: $e\n$st');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Platform-specific options
  // ---------------------------------------------------------------------------

  static FirebaseOptions _resolveOptions() {
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return _iosOptions;
    }
    return _androidOptions;
  }

  /// Android / default options.
  ///
  /// Fill in values from your Firebase console or use env variables.
  static FirebaseOptions get _androidOptions => FirebaseOptions(
        apiKey: dotenv.env['FIREBASE_API_KEY_ANDROID'] ?? _placeholder('API_KEY_ANDROID'),
        appId: dotenv.env['FIREBASE_APP_ID_ANDROID'] ?? _placeholder('APP_ID_ANDROID'),
        messagingSenderId:
            dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? _placeholder('MESSAGING_SENDER_ID'),
        projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? _placeholder('PROJECT_ID'),
        storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? _placeholder('STORAGE_BUCKET'),
      );

  /// iOS / macOS options.
  static FirebaseOptions get _iosOptions => FirebaseOptions(
        apiKey: dotenv.env['FIREBASE_API_KEY_IOS'] ?? _placeholder('API_KEY_IOS'),
        appId: dotenv.env['FIREBASE_APP_ID_IOS'] ?? _placeholder('APP_ID_IOS'),
        messagingSenderId:
            dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? _placeholder('MESSAGING_SENDER_ID'),
        projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? _placeholder('PROJECT_ID'),
        storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? _placeholder('STORAGE_BUCKET'),
        iosBundleId:
            dotenv.env['FIREBASE_IOS_BUNDLE_ID'] ?? _placeholder('IOS_BUNDLE_ID'),
      );

  /// Returns a clearly-marked placeholder so missing keys are obvious at runtime.
  static String _placeholder(String key) => 'REPLACE_ME_$key';

  // ---------------------------------------------------------------------------
  // Firestore collection paths (single source of truth)
  // ---------------------------------------------------------------------------

  static const String usersCollection = 'users';
  static String userProfileDoc(String uid) => 'users/$uid/profile';
  static String userSubscriptionDoc(String uid) => 'users/$uid/subscription';
  static String userUsageDoc(String uid, String date) => 'users/$uid/usage/$date';
  static String userConversationDoc(String uid, String convoId) =>
      'users/$uid/conversations/$convoId';
  static String userConversationsCollection(String uid) => 'users/$uid/conversations';
  static String userUsageCollection(String uid) => 'users/$uid/usage';

  // ---------------------------------------------------------------------------
  // Messaging topic names
  // ---------------------------------------------------------------------------

  static const String topicBroadcast = 'broadcast';
  static const String topicEngagement = 'engagement';
  static const String topicSubscription = 'subscription';
}
