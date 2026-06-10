import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme/app_colors.dart';
import 'providers/theme_provider.dart';
import 'services/analytics_service.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/call_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/daily_screen.dart';
import 'screens/main_shell.dart';
import 'widgets/ongoing_call_banner.dart';

class DostokApp extends StatefulWidget {
  const DostokApp({super.key});

  @override
  State<DostokApp> createState() => _DostokAppState();
}

class _DostokAppState extends State<DostokApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _onAppReady());
  }

  void _onAppReady() {
    final analytics = context.read<AnalyticsService>();
    analytics.logAppOpen();
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final background = isDark ? AppColors.backgroundDark : AppColors.background;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surface;
    final elevatedSurface =
        isDark ? AppColors.surfaceDarkElevated : AppColors.surface;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final divider = isDark ? AppColors.dividerDark : AppColors.divider;
    final primaryContainer =
        isDark ? AppColors.primaryContainerDark : AppColors.primaryContainer;

    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
    ).copyWith(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: primaryContainer,
      onPrimaryContainer: textPrimary,
      surface: surface,
      onSurface: textPrimary,
      surfaceContainerLowest: background,
      surfaceContainerLow: surface,
      surfaceContainer: elevatedSurface,
      surfaceContainerHigh: elevatedSurface,
      surfaceContainerHighest: elevatedSurface,
      outline: divider,
      outlineVariant: divider,
      error: AppColors.error,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Cairo',
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      dividerColor: divider,
      textTheme: ThemeData(brightness: brightness)
          .textTheme
          .apply(
            fontFamily: 'Cairo',
            bodyColor: textPrimary,
            displayColor: textPrimary,
          )
          .copyWith(
            bodySmall: TextStyle(color: textSecondary, fontFamily: 'Cairo'),
            labelSmall: TextStyle(color: textSecondary, fontFamily: 'Cairo'),
          ),
      iconTheme: IconThemeData(color: textPrimary),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
      ),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(48, 48),
          tapTargetSize: MaterialTapTargetSize.padded,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 48),
          tapTargetSize: MaterialTapTargetSize.padded,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          tapTargetSize: MaterialTapTargetSize.padded,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          tapTargetSize: MaterialTapTargetSize.padded,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor:
            isDark ? AppColors.surfaceDarkElevated : const Color(0xFFF5F3FF),
        hintStyle: TextStyle(color: textSecondary, fontFamily: 'Cairo'),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        contentTextStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 14,
          color: textSecondary,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: surface,
        modalBarrierColor: Colors.black54,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: elevatedSurface,
        contentTextStyle: TextStyle(color: textPrimary, fontFamily: 'Cairo'),
        behavior: SnackBarBehavior.floating,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return isDark ? AppColors.textSecondaryDark : null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary.withValues(alpha: 0.35);
          }
          return isDark ? AppColors.dividerDark : null;
        }),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: textPrimary,
        textColor: textPrimary,
        subtitleTextStyle: TextStyle(color: textSecondary, fontFamily: 'Cairo'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final analytics = Provider.of<AnalyticsService>(context, listen: false);
    final analyticsObserver = analytics.observer;
    final themeProv = context.watch<ThemeProvider>();

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Dostok',
      debugShowCheckedModeBanner: false,
      locale: const Locale('en', 'US'),
      supportedLocales: const [
        Locale('en', 'US'),
      ],
      navigatorObservers: [
        if (analyticsObserver != null) analyticsObserver,
      ],
      builder: (context, child) {
        final theme = Theme.of(context);
        return Container(
          color: theme.scaffoldBackgroundColor,
          child: Stack(
            children: [
              if (child != null) child,
              OngoingCallBanner(
                onTap: () => _navigatorKey.currentState?.pushNamed('/call'),
              ),
            ],
          ),
        );
      },
      themeMode: themeProv.themeMode,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      initialRoute: '/splash',
      onGenerateRoute: (settings) {
        if (settings.name == '/call') {
          return PageRouteBuilder<void>(
            settings: settings,
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
            pageBuilder: (context, animation, secondaryAnimation) =>
                const CallScreen(),
          );
        }

        return null;
      },
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/home': (context) => const MainShell(),
        '/chat': (context) => const ChatScreen(),
        '/new-chat': (context) => const ChatScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/daily': (context) => const DailyScreen(),
      },
    );
  }
}
