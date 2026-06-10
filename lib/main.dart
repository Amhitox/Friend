import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'config/firebase_config.dart';
import 'providers/chat_provider.dart';
import 'providers/call_provider.dart';
import 'providers/user_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/daily_provider.dart';
import 'services/subscription_service.dart';
import 'services/billing_service.dart';
import 'services/ad_service.dart';
import 'services/analytics_service.dart';
import 'services/notification_service.dart';
import 'services/auth_service.dart';
import 'services/crash_service.dart';
import 'utils/startup_logger.dart';

Future<void> main() async {
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await _safeRun(
      'StartupLogger.init()',
      () => StartupLogger.init().timeout(const Duration(milliseconds: 500)),
    );
    StartupLogger.log('main() entered zone');

    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Material(
        color: const Color(0xFF7C6BF5),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dostok startup error',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${details.exception}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    };

    await _initializeCore();

    final crashService = CrashService();
    await _safeRun(
      'CrashService.initialize()',
      () =>
          crashService.initialize().timeout(const Duration(milliseconds: 800)),
    );

    final billingService = BillingService.instance;
    final subscriptionService =
        SubscriptionService(billingService: billingService);
    final adService = AdService(subscriptionService);
    final analyticsService = AnalyticsService();
    final notificationService = NotificationService();
    final authService = _createAuthService();

    final themeProvider = ThemeProvider();
    await _safeRun(
      'ThemeProvider.loadTheme()',
      () =>
          themeProvider.loadTheme().timeout(const Duration(milliseconds: 600)),
    );

    StartupLogger.log('runApp() starting');
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ChatProvider()),
          ChangeNotifierProvider(create: (_) => CallProvider()),
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider(create: (_) => DailyProvider()),
          ChangeNotifierProvider.value(value: subscriptionService),
          Provider.value(value: billingService),
          Provider<AdService>.value(value: adService),
          Provider<AnalyticsService>.value(value: analyticsService),
          Provider<NotificationService>.value(value: notificationService),
          Provider<AuthService>.value(value: authService),
          Provider<CrashService>.value(value: crashService),
        ],
        child: const DostokApp(),
      ),
    );
    StartupLogger.log('runApp() completed');

    unawaited(
      _initializeDeferredServices(
        authService: authService,
        billingService: billingService,
        subscriptionService: subscriptionService,
        adService: adService,
        analyticsService: analyticsService,
        notificationService: notificationService,
        crashService: crashService,
      ),
    );
  }, (Object error, StackTrace stackTrace) {
    StartupLogger.log('ZONE ERROR: $error');
    CrashService().handleZoneError(error, stackTrace);
    if (kDebugMode) {
      debugPrint('[main] Unhandled zone error: $error');
      debugPrint('[main] Stack: $stackTrace');
    }
  });
}

Future<void> _initializeCore() async {
  await _safeRun(
    'FirebaseConfig.initialize()',
    () => FirebaseConfig.initialize().timeout(const Duration(seconds: 2)),
  );

  await _safeRun(
    'Hive.initFlutter()',
    () => Hive.initFlutter().timeout(const Duration(seconds: 2)),
  );
  await _safeRun(
    'Hive.openBox(settings)',
    () => Hive.openBox('settings').timeout(const Duration(seconds: 2)),
  );
  await _safeRun(
    'Hive.openBox(conversations)',
    () => Hive.openBox('conversations').timeout(const Duration(seconds: 2)),
  );
}

AuthService _createAuthService() {
  try {
    StartupLogger.log('AuthService() constructor');
    return AuthService();
  } catch (e) {
    StartupLogger.log('AuthService constructor crashed: $e');
    debugPrint('[main] AuthService constructor crashed (non-fatal): $e');
    return AuthService(auth: null);
  }
}

Future<void> _initializeDeferredServices({
  required AuthService authService,
  required BillingService billingService,
  required SubscriptionService subscriptionService,
  required AdService adService,
  required AnalyticsService analyticsService,
  required NotificationService notificationService,
  required CrashService crashService,
}) async {
  StartupLogger.log('deferred services starting');

  await _safeRun(
    'AuthService.signInAnonymously()',
    () => authService.signInAnonymously().timeout(const Duration(seconds: 5)),
  );

  await _safeRun(
    'BillingService.initialize()',
    () => billingService.initialize().timeout(
          const Duration(seconds: 5),
          onTimeout: () => false,
        ),
  );

  await _safeRun(
    'SubscriptionService.initialize()',
    () => subscriptionService.initialize().timeout(const Duration(seconds: 5)),
  );

  await _safeRun(
    'AdService.initialize()',
    () => adService.initialize().timeout(
          const Duration(seconds: 5),
          onTimeout: () => false,
        ),
  );

  await _safeRun(
    'AnalyticsService.initialize()',
    () => analyticsService.initialize().timeout(const Duration(seconds: 5)),
  );

  await _safeRun(
    'NotificationService.initialize()',
    () => notificationService.initialize().timeout(const Duration(seconds: 5)),
  );

  await _safeRun('Crash context setup', () async {
    if (authService.uid != null) {
      await crashService
          .setUserIdentifier(authService.uid!)
          .timeout(const Duration(seconds: 3));
      await analyticsService
          .setUserId(authService.uid!)
          .timeout(const Duration(seconds: 3));
    }
    await crashService
        .setUserProperties(tier: subscriptionService.currentTier.name)
        .timeout(const Duration(seconds: 3));
  });

  StartupLogger.log('deferred services completed');
}

Future<void> _safeRun(String label, Future<dynamic> Function() action) async {
  try {
    StartupLogger.log('$label start');
    await action();
    StartupLogger.log('$label done');
  } catch (e, st) {
    StartupLogger.log('$label failed: $e');
    debugPrint('[main] $label failed (non-fatal): $e');
    if (kDebugMode) {
      debugPrint('$st');
    }
  }
}
