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
  // -----------------------------------------------------------------------
  // Everything inside a guarded zone so CrashService catches async errors.
  // -----------------------------------------------------------------------
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Start logging as early as possible.
    await StartupLogger.init();
    StartupLogger.log('main() entered zone');

    // Make widget-tree errors visible on a real device (red screen instead
    // of the default gray/black release error widget).
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

    // 1.  Load .env and detect demo mode BEFORE any service touches Firebase.
    try {
      StartupLogger.log('FirebaseConfig.initialize() start');
      await FirebaseConfig.initialize()
          .timeout(const Duration(seconds: 5));
      StartupLogger.log(
          'FirebaseConfig.initialize() done — demo=${FirebaseConfig.isDemoMode}');
    } catch (e, st) {
      StartupLogger.log('FirebaseConfig.init failed: $e');
      debugPrint('[main] FirebaseConfig init failed (non-fatal): $e');
    }

    final crashService = CrashService();
    try {
      StartupLogger.log('CrashService.initialize() start');
      await crashService.initialize()
          .timeout(const Duration(seconds: 3));
      StartupLogger.log('CrashService.initialize() done');
    } catch (e, st) {
      StartupLogger.log('Crash init failed: $e');
      debugPrint('[main] Crash init failed (non-fatal): $e');
    }

    // 2.  Hive local storage (local — rarely hangs, but guard anyway)
    try {
      StartupLogger.log('Hive.initFlutter() start');
      await Hive.initFlutter()
          .timeout(const Duration(seconds: 3));
      StartupLogger.log('Hive.initFlutter() done');
      await Hive.openBox('settings')
          .timeout(const Duration(seconds: 3));
      StartupLogger.log('Hive box "settings" opened');
      await Hive.openBox('conversations')
          .timeout(const Duration(seconds: 3));
      StartupLogger.log('Hive box "conversations" opened');
    } catch (e, st) {
      StartupLogger.log('Hive init failed: $e');
      debugPrint('[main] Hive init failed (non-fatal): $e');
    }

    // 3.  Services — each wrapped + timed-out so a single failure/hang
    //     doesn't block the UI from showing.

    // AuthService constructor can throw when Firebase Auth is unavailable.
    // Wrap the constructor itself, not just the async call.
    AuthService? authService;
    try {
      StartupLogger.log('AuthService() constructor');
      authService = AuthService();
      StartupLogger.log('AuthService() created — demo=${authService.isAnonymous}');
    } catch (e, st) {
      StartupLogger.log('AuthService constructor crashed: $e');
      debugPrint('[main] AuthService constructor crashed (non-fatal): $e');
      // The AuthService constructor can fail when Firebase Auth is missing.
      // Passing an explicit null auth bypasses the FirebaseAuth.instance lookup.
      authService = AuthService(auth: null);
    }

    try {
      StartupLogger.log('AuthService.signInAnonymously() start');
      await authService
          .signInAnonymously()
          .timeout(const Duration(seconds: 5));
      StartupLogger.log('AuthService.signInAnonymously() done');
    } catch (e, st) {
      StartupLogger.log('Auth init failed: $e');
      debugPrint('[main] Auth init failed (non-fatal): $e');
    }

    final billingService = BillingService.instance;
    try {
      StartupLogger.log('BillingService.initialize() start');
      await billingService
          .initialize()
          .timeout(const Duration(seconds: 5), onTimeout: () => false);
      StartupLogger.log('BillingService.initialize() done');
    } catch (e, st) {
      StartupLogger.log('Billing init failed: $e');
      debugPrint('[main] Billing init failed (non-fatal): $e');
    }

    SubscriptionService? subscriptionService;
    try {
      StartupLogger.log('SubscriptionService() constructor');
      subscriptionService =
          SubscriptionService(billingService: billingService);
      StartupLogger.log('SubscriptionService() created');
    } catch (e, st) {
      StartupLogger.log('SubscriptionService constructor crashed: $e');
      debugPrint('[main] SubscriptionService constructor crashed: $e');
      // Re-create with a fresh billing instance as last resort.
      subscriptionService = SubscriptionService(billingService: billingService);
    }

    try {
      StartupLogger.log('SubscriptionService.initialize() start');
      await subscriptionService
          .initialize()
          .timeout(const Duration(seconds: 5));
      StartupLogger.log('SubscriptionService.initialize() done');
    } catch (e, st) {
      StartupLogger.log('Subscription init failed: $e');
      debugPrint('[main] Subscription init failed (non-fatal): $e');
    }

    AdService? adService;
    try {
      StartupLogger.log('AdService() constructor');
      adService = AdService(subscriptionService);
      StartupLogger.log('AdService() created');
    } catch (e, st) {
      StartupLogger.log('AdService constructor crashed: $e');
      debugPrint('[main] AdService constructor crashed: $e');
      adService = AdService(subscriptionService);
    }

    try {
      StartupLogger.log('AdService.initialize() start');
      await adService
          .initialize()
          .timeout(const Duration(seconds: 5), onTimeout: () => false);
      StartupLogger.log('AdService.initialize() done');
    } catch (e, st) {
      StartupLogger.log('Ad init failed: $e');
      debugPrint('[main] Ad init failed (non-fatal): $e');
    }

    final analyticsService = AnalyticsService();
    try {
      StartupLogger.log('AnalyticsService.initialize() start');
      await analyticsService
          .initialize()
          .timeout(const Duration(seconds: 5));
      StartupLogger.log('AnalyticsService.initialize() done');
    } catch (e, st) {
      StartupLogger.log('Analytics init failed: $e');
      debugPrint('[main] Analytics init failed (non-fatal): $e');
    }

    final notificationService = NotificationService();
    try {
      StartupLogger.log('NotificationService.initialize() start');
      await notificationService
          .initialize()
          .timeout(const Duration(seconds: 5));
      StartupLogger.log('NotificationService.initialize() done');
    } catch (e, st) {
      StartupLogger.log('Notification init failed: $e');
      debugPrint('[main] Notification init failed (non-fatal): $e');
    }

    // Load persisted theme before runApp so the first frame uses the correct mode.
    final themeProvider = ThemeProvider();
    try {
      await themeProvider.loadTheme()
          .timeout(const Duration(seconds: 2));
      StartupLogger.log('ThemeProvider.loadTheme() done');
    } catch (e, st) {
      StartupLogger.log('Theme load failed: $e');
      debugPrint('[main] Theme load failed (non-fatal): $e');
    }

    // Set crash-context user info now that we know the UID.
    try {
      if (authService.uid != null) {
        await crashService
            .setUserIdentifier(authService.uid!)
            .timeout(const Duration(seconds: 3));
        await analyticsService
            .setUserId(authService.uid!)
            .timeout(const Duration(seconds: 3));
      }
      await crashService
          .setUserProperties(
            tier: subscriptionService.currentTier.name,
          )
          .timeout(const Duration(seconds: 3));
      StartupLogger.log('Crash context set');
    } catch (e, st) {
      StartupLogger.log('Crash context setup failed: $e');
      debugPrint('[main] Crash context setup failed (non-fatal): $e');
    }

    // 4.  Run the app
    StartupLogger.log('runApp() starting');
    runApp(
      MultiProvider(
        providers: [
          // -- Existing providers --
          ChangeNotifierProvider(create: (_) => ChatProvider()),
          ChangeNotifierProvider(create: (_) => CallProvider()),
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider.value(value: themeProvider), // Pre-loaded so first frame has correct theme.
          ChangeNotifierProvider(create: (_) => DailyProvider()),

          // -- Monetization & infrastructure providers --
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
  }, (Object error, StackTrace stackTrace) {
    StartupLogger.log('ZONE ERROR: $error');
    CrashService().handleZoneError(error, stackTrace);
    if (kDebugMode) {
      debugPrint('[main] Unhandled zone error: $error');
      debugPrint('[main] Stack: $stackTrace');
    }
  });
}

