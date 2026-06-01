import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'providers/theme_provider.dart';
import 'services/subscription_service.dart';
import 'services/analytics_service.dart';
import 'services/ad_service.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/call_screen.dart';
import 'screens/paywall_screen.dart';
import 'screens/trial_screen.dart';
import 'models/subscription.dart';
import 'widgets/celebration_screen.dart';
import 'widgets/ad_banner.dart';

class DostokApp extends StatefulWidget {
  const DostokApp({super.key});

  @override
  State<DostokApp> createState() => _DostokAppState();
}

class _DostokAppState extends State<DostokApp> {
  // -----------------------------------------------------------------------
  // Brand colours
  // -----------------------------------------------------------------------
  static const Color _primaryTeal = Color(0xFF7C6BF5);
  static const Color _primaryDark = Color(0xFF5B4BD6);
  static const Color _accentAmber = Color(0xFFC77DFF);

  // VIP-exclusive deep gold accent.
  static const Color _vipGold = Color(0xFFD4A017);

  // -----------------------------------------------------------------------
  // Lifecycle
  // -----------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    // Schedule post-frame work so we can safely access providers.
    WidgetsBinding.instance.addPostFrameCallback((_) => _onAppReady());
  }

  void _onAppReady() {
    final analytics = context.read<AnalyticsService>();
    analytics.logAppOpen();
  }

  // -----------------------------------------------------------------------
  // Build
  // -----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final subscription = Provider.of<SubscriptionService>(context);

    // Pick the seed colour based on subscription tier.
    final bool isVip = subscription.currentTier == SubscriptionTier.vip;
    final Color activeSeed = isVip ? _vipGold : _primaryTeal;
    final Color activeDarkSeed = isVip ? const Color(0xFFB8860B) : _primaryDark;

    // Retrieve the analytics observer for route tracking.
    final analytics = Provider.of<AnalyticsService>(context, listen: false);
    final analyticsObserver = analytics.observer;

    return MaterialApp(
      title: 'Dostok',
      debugShowCheckedModeBanner: false,

      // Localization
      locale: const Locale('ar', 'MA'),
      supportedLocales: const [
        Locale('ar', 'MA'),
        Locale('ar', ''),
        Locale('en', ''),
      ],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Analytics observer -- tracks every push/pop/replace automatically.
      navigatorObservers: [
        if (analyticsObserver != null) analyticsObserver,
      ],

      // -------------------------------------------------------------------
      // Light Theme
      // -------------------------------------------------------------------
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: activeSeed,
          primary: activeSeed,
          secondary: _accentAmber,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F5FF),
        textTheme: GoogleFonts.cairoTextTheme(),
        appBarTheme: AppBarTheme(
          backgroundColor: activeSeed,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.cairo(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: activeSeed,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: isVip ? _vipGold : _accentAmber,
          foregroundColor: Colors.white,
        ),
      ),

      // -------------------------------------------------------------------
      // Dark Theme
      // -------------------------------------------------------------------
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: activeDarkSeed,
          primary: activeDarkSeed,
          secondary: _accentAmber,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        textTheme: GoogleFonts.cairoTextTheme(
          ThemeData.dark().textTheme,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.cairo(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: activeDarkSeed,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: isVip ? _vipGold : _accentAmber,
          foregroundColor: Colors.black,
        ),
      ),

      themeMode: themeProvider.themeMode,

      // -------------------------------------------------------------------
      // Routes
      // -------------------------------------------------------------------
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/home': (context) => const HomeScreen(),
        '/chat': (context) => const ChatScreen(),
        '/call': (context) => const CallScreen(),
        '/paywall': (context) => const PaywallScreen(),
        '/trial': (context) => const TrialScreen(),
      },

      // Routes that need runtime arguments (celebration overlay).
      onGenerateRoute: (settings) {
        if (settings.name == '/celebration') {
          final args = settings.arguments as Map<String, dynamic>?;
          final tier = args?['tier'] as SubscribedTier? ?? SubscribedTier.premium;
          return _TransparentRoute(
            builder: (_) => CelebrationOverlay(
              tier: tier,
              onDismiss: () => Navigator.of(_).pop(),
            ),
          );
        }
        return null;
      },

      // -------------------------------------------------------------------
      // Global ad banner -- sits above the bottom of every screen
      // -------------------------------------------------------------------
      builder: (context, child) {
        return _AppShell(child: child);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _AppShell: wraps the navigator with the global ad banner
// ---------------------------------------------------------------------------

class _AppShell extends StatelessWidget {
  const _AppShell({required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    // Only show the ad banner when the user is on the free tier.
    final subscription = Provider.of<SubscriptionService>(context);
    final adService = Provider.of<AdService>(context, listen: false);
    final bool showBanner = subscription.showAds;

    return Column(
      children: [
        Expanded(child: child ?? const SizedBox.shrink()),
        if (showBanner) AdBanner(adService: adService),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _TransparentRoute: used for overlays like the celebration screen
// ---------------------------------------------------------------------------

class _TransparentRoute extends PageRouteBuilder {
  _TransparentRoute({required WidgetBuilder builder})
      : super(
          opaque: false,
          barrierDismissible: true,
          barrierColor: Colors.black54,
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
}
