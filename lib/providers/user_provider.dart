import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/user_profile.dart';

/// Manages the local user's profile and relationship metrics for Dostok.
///
/// Handles first-time initialization, preference updates, and the evolving
/// relationship level that grows with each interaction. Persisted via Hive.
class UserProvider extends ChangeNotifier {
  static const String _boxName = 'settings';
  static const String _profileKey = 'userProfile';

  UserProfile? _currentUser;
  bool _isLoading = false;
  String? _error;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  /// The current user profile, or null if not yet initialized.
  UserProfile? get currentUser => _currentUser;

  /// Whether a profile operation is in progress.
  bool get isLoading => _isLoading;

  /// Whether the user has completed onboarding.
  bool get isInitialized => _currentUser != null;

  /// The user's display name, or a default greeting.
  String get displayName => _currentUser?.name ?? 'Sadiq';

  /// The user's preferred language setting.
  PreferredLanguage get preferredLanguage =>
      _currentUser?.preferredLanguage ?? PreferredLanguage.mixed;

  /// The last error message, if any.
  String? get error => _error;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Loads the persisted user profile from Hive.
  ///
  /// Returns true if a profile was found, false if the user needs onboarding.
  Future<bool> loadUser() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final box = await Hive.openBox(_boxName);
      final data = box.get(_profileKey);

      if (data != null && data is Map) {
        _currentUser = UserProfile(
          name: data['name'] as String? ?? 'Sadiq',
          preferredLanguage: PreferredLanguage.values.firstWhere(
            (l) => l.name == data['preferredLanguage'],
            orElse: () => PreferredLanguage.mixed,
          ),
          humorLevel: data['humorLevel'] as int? ?? 5,
          empathyLevel: data['empathyLevel'] as int? ?? 5,
          formalityLevel: data['formalityLevel'] as int? ?? 3,
          relationshipLevel: data['relationshipLevel'] as int? ?? 0,
          totalMessages: data['totalMessages'] as int? ?? 0,
          daysActive: data['daysActive'] as int? ?? 0,
          firstInteractionDate: data['firstInteractionDate'] != null
              ? DateTime.tryParse(data['firstInteractionDate'] as String) ??
                  DateTime.now()
              : DateTime.now(),
          avatarPath: data['avatarPath'] as String?,
        );
        return true;
      }
      return false;
    } catch (e, st) {
      dev.log('UserProvider.loadUser failed', error: e, stackTrace: st);
      _error = 'Failed to load profile.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Creates a new user profile with the given [name] and saves it.
  ///
  /// Called during onboarding when the user enters their name for the first
  /// time. Initializes relationship metrics to starting values.
  Future<void> initializeUser(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      _error = 'Please enter your name.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = UserProfile(
        name: trimmed,
        firstInteractionDate: DateTime.now(),
      );
      await _persistProfile();
      dev.log('User initialized: $trimmed');
    } catch (e, st) {
      dev.log('UserProvider.initializeUser failed', error: e, stackTrace: st);
      _error = 'Failed to save profile.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Profile updates
  // ---------------------------------------------------------------------------

  /// Updates the user profile with new values.
  ///
  /// Any parameter left as null keeps the current value. Only changed fields
  /// trigger a Hive write.
  Future<void> updateProfile({
    String? name,
    PreferredLanguage? preferredLanguage,
    int? humorLevel,
    int? empathyLevel,
    int? formalityLevel,
    String? avatarPath,
  }) async {
    if (_currentUser == null) return;
    final user = _currentUser!;

    // Clamp levels to valid ranges.
    int? clamp(int? value, int min, int max) {
      if (value == null) return null;
      return value.clamp(min, max);
    }

    _currentUser = user.copyWith(
      name: name?.trim(),
      preferredLanguage: preferredLanguage,
      humorLevel: clamp(humorLevel, 0, 10),
      empathyLevel: clamp(empathyLevel, 0, 10),
      formalityLevel: clamp(formalityLevel, 0, 10),
      avatarPath: avatarPath,
    );

    notifyListeners();
    await _persistProfile();
  }

  /// Increments the total message count and potentially the relationship level.
  ///
  /// Call this each time the user sends a message. The relationship level
  /// increases by 1 for every 10 messages (up to a max of 100).
  Future<void> incrementMessages() async {
    if (_currentUser == null) return;
    final user = _currentUser!;

    final newTotal = user.totalMessages + 1;
    final newRelationship =
        (newTotal % 10 == 0 && user.relationshipLevel < 100)
            ? user.relationshipLevel + 1
            : user.relationshipLevel;

    _currentUser = user.copyWith(
      totalMessages: newTotal,
      relationshipLevel: newRelationship,
    );

    notifyListeners();
    await _persistProfile();
  }

  /// Increments the days-active counter if the user hasn't interacted today.
  ///
  /// Call once per app session. Checks the last active date stored in Hive
  /// to avoid double-counting.
  Future<void> trackDailyActive() async {
    if (_currentUser == null) return;
    final user = _currentUser!;

    try {
      final box = await Hive.openBox(_boxName);
      final lastActiveStr = box.get('lastActiveDate') as String?;

      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      if (lastActiveStr != null) {
        final lastActive = DateTime.tryParse(lastActiveStr);
        if (lastActive != null) {
          final lastDate =
              DateTime(lastActive.year, lastActive.month, lastActive.day);
          if (lastDate.isAtSameMomentAs(todayDate)) {
            return; // Already counted today.
          }
        }
      }

      _currentUser = user.copyWith(
        daysActive: user.daysActive + 1,
      );
      notifyListeners();

      await box.put('lastActiveDate', todayDate.toIso8601String());
      await _persistProfile();
    } catch (e, st) {
      dev.log('UserProvider.trackDailyActive failed',
          error: e, stackTrace: st);
    }
  }

  /// Resets the profile to a blank state (e.g., for account deletion).
  Future<void> clearProfile() async {
    _currentUser = null;
    _error = null;
    notifyListeners();

    try {
      final box = await Hive.openBox(_boxName);
      await box.delete(_profileKey);
    } catch (e, st) {
      dev.log('UserProvider.clearProfile failed', error: e, stackTrace: st);
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Persists the current profile to Hive.
  Future<void> _persistProfile() async {
    if (_currentUser == null) return;
    final user = _currentUser!;

    try {
      final box = await Hive.openBox(_boxName);
      await box.put(_profileKey, {
        'name': user.name,
        'preferredLanguage': user.preferredLanguage.name,
        'humorLevel': user.humorLevel,
        'empathyLevel': user.empathyLevel,
        'formalityLevel': user.formalityLevel,
        'relationshipLevel': user.relationshipLevel,
        'totalMessages': user.totalMessages,
        'daysActive': user.daysActive,
        'firstInteractionDate': user.firstInteractionDate.toIso8601String(),
        'avatarPath': user.avatarPath,
      });
    } catch (e, st) {
      dev.log('UserProvider._persistProfile failed', error: e, stackTrace: st);
    }
  }
}
