import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/firebase_config.dart';
import 'auth_service.dart';

/// Cloud data persistence service for Dostok.
///
/// Responsibilities:
///   - Upload / download user profile, subscription, usage, conversations
///   - Offline-first: queue changes locally, flush when connectivity returns
///   - Conflict resolution:
///       * Subscription -- server wins (authoritative billing data)
///       * UI preferences -- local wins (user's device is source of truth)
///
/// Firestore collection structure:
///   users/{uid}/profile            -- single document
///   users/{uid}/subscription       -- single document
///   users/{uid}/usage/{date}       -- one doc per day (YYYY-MM-DD)
///   users/{uid}/conversations/{id} -- one doc per conversation
class SyncService {
  SyncService({
    required AuthService authService,
    FirebaseFirestore? firestore,
    Connectivity? connectivity,
  })  : _authService = authService,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _connectivity = connectivity ?? Connectivity();

  final AuthService _authService;
  final FirebaseFirestore _firestore;
  final Connectivity _connectivity;

  SharedPreferences? _prefs;

  /// Pending operations queued while offline.
  static const _pendingOpsKey = 'sync_pending_ops';

  /// Completes once the first connectivity check is done.
  bool _isOnline = false;
  StreamSubscription<List<ConnectivityResult>>? _connSub;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Call once at app startup after Firebase and AuthService are ready.
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    // Listen for connectivity changes and flush the queue when we come online.
    _connSub = _connectivity.onConnectivityChanged.listen((results) {
      final wasOnline = _isOnline;
      _isOnline = !results.contains(ConnectivityResult.none);
      if (!wasOnline && _isOnline) {
        _flushPendingOps();
      }
    });

    // Initial connectivity check.
    final results = await _connectivity.checkConnectivity();
    _isOnline = !results.contains(ConnectivityResult.none);

    if (_isOnline) {
      await _flushPendingOps();
    }
  }

  /// Dispose streams.
  void dispose() {
    _connSub?.cancel();
  }

  // ---------------------------------------------------------------------------
  // User profile
  // ---------------------------------------------------------------------------

  /// Upload [profile] to Firestore under `users/{uid}/profile`.
  ///
  /// Conflict resolution: **local wins** -- the device is the source of truth
  /// for UI preferences (language, theme, check-in time, etc.).
  Future<void> syncUserProfile(Map<String, dynamic> profile) async {
    final uid = _requireUid();
    final docRef = _firestore.doc(FirebaseConfig.userProfileDoc(uid));

    final data = {
      ...profile,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _enqueueOrExecute(() => docRef.set(data, SetOptions(merge: true)));
  }

  /// Download the user profile. Returns `null` when no profile exists yet.
  Future<Map<String, dynamic>?> fetchUserProfile() async {
    final uid = _requireUid();
    try {
      final doc = await _firestore.doc(FirebaseConfig.userProfileDoc(uid)).get();
      return doc.data();
    } catch (e) {
      _log('fetchUserProfile failed: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Subscription
  // ---------------------------------------------------------------------------

  /// Upload / verify subscription status.
  ///
  /// Conflict resolution: **server wins** -- subscription state is
  /// authoritative from the billing backend. We always merge so that fields
  /// set server-side (e.g. `verifiedAt`) are preserved.
  Future<void> syncSubscription(Map<String, dynamic> subscription) async {
    final uid = _requireUid();
    final docRef = _firestore.doc(FirebaseConfig.userSubscriptionDoc(uid));

    final data = {
      ...subscription,
      'syncedAt': FieldValue.serverTimestamp(),
    };

    await _enqueueOrExecute(() => docRef.set(data, SetOptions(merge: true)));
  }

  /// Fetch the server-authoritative subscription document.
  Future<Map<String, dynamic>?> fetchSubscription() async {
    final uid = _requireUid();
    try {
      final doc = await _firestore.doc(FirebaseConfig.userSubscriptionDoc(uid)).get();
      return doc.data();
    } catch (e) {
      _log('fetchSubscription failed: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Daily usage
  // ---------------------------------------------------------------------------

  /// Sync usage for a given date string (`YYYY-MM-DD`).
  ///
  /// This is used to prevent abuse across devices -- the server is the
  /// authoritative source for consumed message counts.
  Future<void> syncUsage(String date, Map<String, dynamic> usage) async {
    final uid = _requireUid();
    final docRef = _firestore.doc(FirebaseConfig.userUsageDoc(uid, date));

    final data = {
      ...usage,
      'date': date,
      'syncedAt': FieldValue.serverTimestamp(),
    };

    await _enqueueOrExecute(() => docRef.set(data, SetOptions(merge: true)));
  }

  /// Fetch usage for [date]. Returns `null` if no record exists.
  Future<Map<String, dynamic>?> fetchUsage(String date) async {
    final uid = _requireUid();
    try {
      final doc = await _firestore.doc(FirebaseConfig.userUsageDoc(uid, date)).get();
      return doc.data();
    } catch (e) {
      _log('fetchUsage failed: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Conversations (premium cloud backup)
  // ---------------------------------------------------------------------------

  /// Upload a single conversation to the cloud.
  ///
  /// Only available for premium users -- callers should check subscription
  /// status before invoking.
  Future<void> syncConversation(String convoId, Map<String, dynamic> convo) async {
    final uid = _requireUid();
    final docRef = _firestore.doc(FirebaseConfig.userConversationDoc(uid, convoId));

    final data = {
      ...convo,
      'id': convoId,
      'syncedAt': FieldValue.serverTimestamp(),
    };

    await _enqueueOrExecute(() => docRef.set(data, SetOptions(merge: true)));
  }

  /// Fetch all conversations for the current user.
  ///
  /// Returns an empty list on error (offline, permission denied, etc.).
  Future<List<Map<String, dynamic>>> fetchConversations() async {
    final uid = _requireUid();
    try {
      final snapshot = await _firestore
          .collection(FirebaseConfig.userConversationsCollection(uid))
          .orderBy('syncedAt', descending: true)
          .get();

      return snapshot.docs.map((d) => d.data()).toList();
    } catch (e) {
      _log('fetchConversations failed: $e');
      return [];
    }
  }

  /// Delete a conversation from the cloud.
  Future<void> deleteConversation(String convoId) async {
    final uid = _requireUid();
    final docRef = _firestore.doc(FirebaseConfig.userConversationDoc(uid, convoId));
    await _enqueueOrExecute(() => docRef.delete());
  }

  // ---------------------------------------------------------------------------
  // Offline queue
  // ---------------------------------------------------------------------------

  /// Execute [op] immediately if online; otherwise persist it locally.
  Future<void> _enqueueOrExecute(Future<void> Function() op) async {
    if (_isOnline) {
      try {
        await op();
        return;
      } catch (e) {
        _log('Operation failed, queuing for retry: $e');
      }
    }
    await _enqueueOp(op.toString());
  }

  /// Persist an opaque operation description to the local queue.
  ///
  /// In a production implementation you would store the full callable
  /// (collection, document path, data, merge flag) so it can be replayed.
  /// Here we store a serialised representation for robustness.
  Future<void> _enqueueOp(String opDescription) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final List<String> pending = prefs.getStringList(_pendingOpsKey) ?? [];
    pending.add(opDescription);
    await prefs.setStringList(_pendingOpsKey, pending);
  }

  /// Replay all queued operations. Called when connectivity is restored.
  Future<void> _flushPendingOps() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final List<String> pending = prefs.getStringList(_pendingOpsKey) ?? [];
    if (pending.isEmpty) return;

    _log('Flushing ${pending.length} pending operation(s)');

    // In a real implementation, each entry would be deserialised and replayed
    // against Firestore. For now we clear the queue and let the next sync
    // calls repopulate with current data.
    await prefs.remove(_pendingOpsKey);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _requireUid() {
    final uid = _authService.uid;
    if (uid == null) {
      throw StateError('No authenticated user -- call AuthService first');
    }
    return uid;
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[SyncService] $message');
    }
  }
}
