import 'package:flutter/material.dart';

import '../screens/splash_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/home_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/call_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/manage_subscription_screen.dart';
// TODO: Uncomment when these screens are implemented
// import '../screens/paywall_screen.dart';
// import '../screens/celebration_overlay.dart';

/// Centralized routing configuration for the Dostok app.
///
/// Defines named route constants and provides [onGenerateRoute] for
/// route resolution with custom page transitions (slide and fade).
///
/// Usage in `MaterialApp`:
/// ```dart
/// MaterialApp(
///   initialRoute: AppRouter.splash,
///   onGenerateRoute: AppRouter.onGenerateRoute,
/// );
/// ```
///
/// Navigation:
/// ```dart
/// Navigator.pushNamed(context, AppRouter.chat);
/// ```
abstract final class AppRouter {
  // ===========================================================================
  // Route Name Constants
  // ===========================================================================

  /// Splash / loading screen shown on app launch.
  static const String splash = '/splash';

  /// Multi-page onboarding flow for new users.
  static const String onboarding = '/onboarding';

  /// Main home screen with bottom navigation.
  static const String home = '/home';

  /// Chat conversation screen.
  static const String chat = '/chat';

  /// Starts a fresh chat conversation from the center plus button.
  static const String newChat = '/new-chat';

  /// Voice call screen.
  static const String call = '/call';

  /// User profile screen.
  static const String profile = '/profile';

  /// Settings screen.
  static const String settings = '/settings';

  // ─── Monetization Routes ──────────────────────────────────────────────

  /// Paywall screen for subscription purchases.
  static const String paywall = '/paywall';

  /// Subscription management screen.
  static const String manageSubscription = '/manage-subscription';

  /// Celebration overlay for milestones and achievements.
  static const String celebration = '/celebration';

  // ===========================================================================
  // Route Map (for quick lookup)
  // ===========================================================================

  /// Complete map of route names to their builder functions.
  ///
  /// Useful for `routes:` parameter in `MaterialApp` when custom transitions
  /// are not needed.
  static final Map<String, WidgetBuilder> routes = {
    splash: (_) => const SplashScreen(),
    onboarding: (_) => const OnboardingScreen(),
    home: (_) => const HomeScreen(),
    chat: (_) => const ChatScreen(),
    newChat: (_) => const ChatScreen(),
    call: (_) => const CallScreen(),
    profile: (_) => const ProfileScreen(),
    settings: (_) => const SettingsScreen(),
    manageSubscription: (_) => const ManageSubscriptionScreen(),
    // TODO: Uncomment when these screens are implemented
    // paywall: (_) => const PaywallScreen(),
    // celebration: (_) => const CelebrationOverlay(),
  };

  // ===========================================================================
  // Route Generator
  // ===========================================================================

  /// Generates routes with custom page transitions based on the route name.
  ///
  /// Falls back to a [MaterialPageRoute] if the route name is unknown. The
  /// transition style is chosen based on the destination screen:
  ///
  /// - **Splash/Onboarding**: fade transition (no directional motion).
  /// - **Home**: fade + scale (launch feel).
  /// - **Chat**: slide from right (forward navigation feel).
  /// - **Call**: no transition, so the call UI is stable on entry.
  /// - **Profile/Settings**: slide from bottom (modal sheet feel).
  /// - **Paywall**: slide from bottom (modal sheet feel).
  /// - **Celebration**: fade (overlay feel).
  static Route<dynamic>? onGenerateRoute(RouteSettings routeSettings) {
    final name = routeSettings.name;

    Widget? page;
    _TransitionType transition;

    switch (name) {
      case splash:
        page = const SplashScreen();
        transition = _TransitionType.fade;
      case onboarding:
        page = const OnboardingScreen();
        transition = _TransitionType.fade;
      case home:
        page = const HomeScreen();
        transition = _TransitionType.fadeScale;
      case chat:
        page = const ChatScreen();
        transition = _TransitionType.slideFromRight;
      case newChat:
        page = const ChatScreen();
        transition = _TransitionType.slideFromRight;
      case call:
        page = const CallScreen();
        transition = _TransitionType.none;
      case profile:
        page = const ProfileScreen();
        transition = _TransitionType.slideFromBottom;
      case settings:
        page = const SettingsScreen();
        transition = _TransitionType.slideFromBottom;

      // ─── Monetization Routes ──────────────────────────────────────────

      case paywall:
        // TODO: Replace with PaywallScreen() when implemented
        page = const _PlaceholderScreen(title: 'Paywall');
        transition = _TransitionType.slideFromBottom;

      case manageSubscription:
        page = const ManageSubscriptionScreen();
        transition = _TransitionType.slideFromRight;

      case celebration:
        // TODO: Replace with CelebrationOverlay() when implemented
        page = const _PlaceholderScreen(title: 'Celebration');
        transition = _TransitionType.fade;

      default:
        return null; // Let MaterialApp handle unknown routes.
    }

    return _buildRoute(
      page: page,
      settings: routeSettings,
      transition: transition,
    );
  }

  // ===========================================================================
  // Transition Builders
  // ===========================================================================

  /// Builds a [PageRouteBuilder] with the specified transition type.
  static PageRouteBuilder<T> _buildRoute<T>({
    required Widget page,
    required RouteSettings settings,
    required _TransitionType transition,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: transition == _TransitionType.none
          ? Duration.zero
          : const Duration(milliseconds: 350),
      reverseTransitionDuration: transition == _TransitionType.none
          ? Duration.zero
          : const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        switch (transition) {
          case _TransitionType.none:
            return child;
          case _TransitionType.fade:
            return _fadeTransition(animation, child);
          case _TransitionType.fadeScale:
            return _fadeScaleTransition(animation, child);
          case _TransitionType.slideFromRight:
            return _slideFromRight(animation, child);
          case _TransitionType.slideFromLeft:
            return _slideFromLeft(animation, child);
          case _TransitionType.slideFromBottom:
            return _slideFromBottom(animation, child);
        }
      },
    );
  }

  /// Standard fade-in transition.
  static Widget _fadeTransition(Animation<double> animation, Widget child) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      ),
      child: child,
    );
  }

  /// Fade + subtle scale-up transition, used for "launching" a screen.
  static Widget _fadeScaleTransition(
    Animation<double> animation,
    Widget child,
  ) {
    final fadeAnim = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOut,
    );
    final scaleAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      ),
    );
    return FadeTransition(
      opacity: fadeAnim,
      child: ScaleTransition(
        scale: scaleAnim,
        child: child,
      ),
    );
  }

  /// Slide from right to left (LTR), used for forward navigation.
  static Widget _slideFromRight(Animation<double> animation, Widget child) {
    final tween = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).chain(CurveTween(curve: Curves.easeOutCubic));
    return SlideTransition(
      position: animation.drive(tween),
      child: child,
    );
  }

  /// Slide from left to right (RTL), used for back navigation.
  static Widget _slideFromLeft(Animation<double> animation, Widget child) {
    final tween = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).chain(CurveTween(curve: Curves.easeOutCubic));
    return SlideTransition(
      position: animation.drive(tween),
      child: child,
    );
  }

  /// Slide from bottom up, used for modal-style screens.
  static Widget _slideFromBottom(Animation<double> animation, Widget child) {
    final tween = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).chain(CurveTween(curve: Curves.easeOutCubic));
    final fadeAnim = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOut,
    );
    return FadeTransition(
      opacity: fadeAnim,
      child: SlideTransition(
        position: animation.drive(tween),
        child: child,
      ),
    );
  }

  // ===========================================================================
  // Navigation Helpers
  // ===========================================================================

  /// Pushes a named route with the app's custom transition.
  ///
  /// Convenience wrapper around [Navigator.pushNamed].
  static Future<T?> push<T>(BuildContext context, String routeName) {
    return Navigator.of(context).pushNamed(routeName);
  }

  /// Replaces the current route with a named route.
  ///
  /// Useful for splash -> home navigation where you don't want to keep the
  /// splash in the back stack.
  static Future<T?> pushReplacement<T>(BuildContext context, String routeName) {
    return Navigator.of(context).pushReplacementNamed(routeName);
  }

  /// Pushes a named route and clears the entire back stack.
  ///
  /// Used after onboarding completion to land on a clean home screen.
  static Future<T?> pushAndClearStack<T>(
    BuildContext context,
    String routeName,
  ) {
    return Navigator.of(context).pushNamedAndRemoveUntil(
      routeName,
      (_) => false,
    );
  }

  /// Pops the current route off the navigator.
  static void pop<T>(BuildContext context, [T? result]) {
    Navigator.of(context).pop(result);
  }

  /// Returns `true` if the navigator can pop (has more than one route).
  static bool canPop(BuildContext context) {
    return Navigator.of(context).canPop();
  }
}

// =============================================================================
// Private transition type enum
// =============================================================================

/// Available page transition styles.
enum _TransitionType {
  /// No animated transition.
  none,

  /// Simple cross-fade.
  fade,

  /// Fade combined with subtle scale-up.
  fadeScale,

  /// Slide from the right edge (forward navigation).
  slideFromRight,

  /// Slide from the left edge (back navigation).
  slideFromLeft,

  /// Slide from the bottom with fade (modal feel).
  slideFromBottom,
}

// =============================================================================
// Placeholder screen (remove when actual screens are connected)
// =============================================================================

/// Temporary placeholder screen for unimplemented routes.
class _PlaceholderScreen extends StatelessWidget {
  final String title;

  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Coming soon!',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
