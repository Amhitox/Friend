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

Future<void> main() async {
  // -----------------------------------------------------------------------
  // 1.  Bindings & Firebase (must come before everything else)
  // -----------------------------------------------------------------------
  WidgetsFlutterBinding.ensureInitialized();

  final crashService = CrashService();
  await crashService.initialize();

  await FirebaseConfig.initialize();

  // -----------------------------------------------------------------------
  // 2.  Hive local storage
  // -----------------------------------------------------------------------
  await Hive.initFlutter();
  await Hive.openBox('settings');
  await Hive.openBox('conversations');

  // -----------------------------------------------------------------------
  // 3.  Services
  // -----------------------------------------------------------------------
  final authService = AuthService();
  await authService.signInAnonymously();

  final billingService = BillingService.instance;
  await billingService.initialize();

  final subscriptionService = SubscriptionService(billingService: billingService);
  await subscriptionService.initialize();

  final adService = AdService(subscriptionService);
  await adService.initialize();

  final analyticsService = AnalyticsService();
  await analyticsService.initialize();

  final notificationService = NotificationService();
  await notificationService.initialize();

  // Set crash-context user info now that we know the UID.
  if (authService.uid != null) {
    await crashService.setUserIdentifier(authService.uid!);
    await analyticsService.setUserId(authService.uid!);
  }
  await crashService.setUserProperties(
    tier: subscriptionService.currentTier.name,
  );

  // -----------------------------------------------------------------------
  // 4.  Run the app inside a guarded zone
  // -----------------------------------------------------------------------
  runZonedGuarded<Future<void>>(() async {
    runApp(
      MultiProvider(
        providers: [
          // -- Existing providers --
          ChangeNotifierProvider(create: (_) => ChatProvider()),
          ChangeNotifierProvider(create: (_) => CallProvider()),
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
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
  }, (Object error, StackTrace stackTrace) {
    crashService.handleZoneError(error, stackTrace);
    if (kDebugMode) {
      debugPrint('[main] Unhandled zone error: $error');
      debugPrint('[main] Stack: $stackTrace');
    }
  });
}
