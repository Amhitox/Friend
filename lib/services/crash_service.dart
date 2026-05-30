import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class CrashService {
  static final CrashService _instance = CrashService._internal();
  factory CrashService() => _instance;
  CrashService._internal();

  FirebaseCrashlytics get _crashlytics => FirebaseCrashlytics.instance;

  Future<void> initialize() async {
    // Enable Crashlytics collection (disable in debug for development)
    await _crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);

    // Catch Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);

      if (kDebugMode) {
        debugPrint('[CrashService] Flutter error: ${details.exception}');
        debugPrint('[CrashService] Stack: ${details.stack}');
      }

      // Report to Crashlytics in release mode
      if (!kDebugMode) {
        _crashlytics.recordFlutterFatalError(details);
      }
    };

    if (kDebugMode) {
      debugPrint('[CrashService] Initialized (collection disabled in debug)');
    }
  }

  /// Zone error handler for catching async errors
  /// Use this in main() to wrap the app:
  /// ```dart
  /// void main() async {
  ///   runZonedGuarded<Future<void>>(() async {
  ///     WidgetsFlutterBinding.ensureInitialized();
  ///     await CrashService().initialize();
  ///     runApp(MyApp());
  ///   }, CrashService().handleZoneError);
  /// }
  /// ```
  void handleZoneError(Object error, StackTrace stackTrace) {
    if (kDebugMode) {
      debugPrint('[CrashService] Zone error: $error');
      debugPrint('[CrashService] Stack: $stackTrace');
    }

    // Report to Crashlytics in release mode
    if (!kDebugMode) {
      _crashlytics.recordError(error, stackTrace, fatal: true);
    }
  }

  /// Record a non-fatal error with optional context
  Future<void> recordError(
    dynamic error,
    StackTrace stack, {
    String? reason,
    bool fatal = false,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('[CrashService] Error: $error');
        debugPrint('[CrashService] Reason: $reason');
        debugPrint('[CrashService] Stack: $stack');
      }

      // Add additional data as custom keys if provided
      if (additionalData != null) {
        for (final entry in additionalData.entries) {
          await setCustomKey(entry.key, entry.value.toString());
        }
      }

      await _crashlytics.recordError(
        error,
        stack,
        reason: reason,
        fatal: fatal,
        information: additionalData?.entries
            .map((e) => '${e.key}: ${e.value}')
            .toList() ?? [],
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CrashService] Failed to record error: $e');
      }
    }
  }

  /// Log a breadcrumb message for debugging
  /// These appear in the Crashlytics console as logs leading up to a crash
  Future<void> log(String message) async {
    try {
      if (kDebugMode) {
        debugPrint('[CrashService] Log: $message');
      }
      await _crashlytics.log(message);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CrashService] Failed to log: $e');
      }
    }
  }

  /// Set a custom key-value pair for crash context
  Future<void> setCustomKey(String key, dynamic value) async {
    try {
      if (value is String) {
        await _crashlytics.setCustomKey(key, value);
      } else if (value is int) {
        await _crashlytics.setCustomKey(key, value);
      } else if (value is double) {
        await _crashlytics.setCustomKey(key, value);
      } else if (value is bool) {
        await _crashlytics.setCustomKey(key, value);
      } else {
        await _crashlytics.setCustomKey(key, value.toString());
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CrashService] Failed to set custom key: $e');
      }
    }
  }

  /// Set the user identifier for crash reports
  Future<void> setUserIdentifier(String uid) async {
    try {
      await _crashlytics.setUserIdentifier(uid);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CrashService] Failed to set user identifier: $e');
      }
    }
  }

  /// Trigger a test crash (debug builds only)
  void crash() {
    if (kDebugMode) {
      debugPrint('[CrashService] Triggering test crash...');
      // Use a delayed call to ensure the debug print is visible
      Future.delayed(const Duration(milliseconds: 100), () {
        throw Exception('[CrashService] Test crash triggered');
      });
    } else {
      _crashlytics.crash();
    }
  }

  /// Set user properties that appear in crash reports
  Future<void> setUserProperties({
    String? tier,
    String? appVersion,
    String? platform,
  }) async {
    try {
      if (tier != null) await setCustomKey('user_tier', tier);
      if (appVersion != null) await setCustomKey('app_version', appVersion);
      if (platform != null) await setCustomKey('platform', platform);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CrashService] Failed to set user properties: $e');
      }
    }
  }

  /// Mark a crash as expected (non-fatal with context)
  Future<void> recordFlutterError(
    FlutterErrorDetails details, {
    bool fatal = false,
  }) async {
    try {
      if (!kDebugMode) {
        if (fatal) {
          await _crashlytics.recordFlutterFatalError(details);
        } else {
          await _crashlytics.recordFlutterError(details);
        }
      } else {
        debugPrint('[CrashService] Flutter error: ${details.exception}');
        debugPrint('[CrashService] Library: ${details.library}');
        debugPrint('[CrashService] Context: ${details.context}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CrashService] Failed to record Flutter error: $e');
      }
    }
  }

  /// Check if Crashlytics is enabled
  bool get isCrashlyticsCollectionEnabled => _crashlytics.isCrashlyticsCollectionEnabled;
}
