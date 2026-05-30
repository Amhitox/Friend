import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:darija_friend/widgets/chat_bubble.dart';
import 'package:darija_friend/widgets/loading_widget.dart';
import 'package:darija_friend/widgets/error_widget.dart';
import 'package:darija_friend/widgets/empty_state.dart';
import 'package:darija_friend/l10n/app_localizations.dart';
import 'package:darija_friend/models/message.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Wraps a widget under test with the minimum boilerplate needed by Dostok
/// widgets: a [MaterialApp] with a [Scaffold], the [AppLocalizations] delegate,
/// and an optional locale override.
Widget buildTestable(
  Widget child, {
  Locale locale = const Locale('ar', 'MA'),
  ThemeMode themeMode = ThemeMode.light,
}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: const [
      Locale('ar', 'MA'),
      Locale('ar'),
      Locale('en'),
    ],
    localizationsDelegates: const [
      AppLocalizationsDelegate(),
      DefaultWidgetsLocalizations.delegate,
      DefaultMaterialLocalizations.delegate,
    ],
    themeMode: themeMode,
    theme: ThemeData.light(),
    darkTheme: ThemeData.dark(),
    home: Scaffold(body: child),
  );
}

/// Creates a minimal [Message] for testing.
Message _testMessage({
  String id = 'test-001',
  String content = 'سلام! لاباس عليك؟',
  bool isFromUser = true,
  MessageType type = MessageType.text,
  bool isRead = false,
}) {
  return Message(
    id: id,
    content: content,
    isFromUser: isFromUser,
    timestamp: DateTime(2026, 5, 30, 14, 30),
    type: type,
    isRead: isRead,
  );
}

// ---------------------------------------------------------------------------
// Smoke tests -- app renders
// ---------------------------------------------------------------------------

void main() {
  group('Smoke tests -- app renders', () {
    testWidgets('MaterialApp with Dostok configuration renders without error',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar', 'MA'),
          supportedLocales: const [
            Locale('ar', 'MA'),
            Locale('ar'),
            Locale('en'),
          ],
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            DefaultWidgetsLocalizations.delegate,
            DefaultMaterialLocalizations.delegate,
          ],
          theme: ThemeData.light(),
          home: const Scaffold(
            body: Center(child: Text('دوستك')),
          ),
        ),
      );

      expect(find.text('دوستك'), findsOneWidget);
    });

    testWidgets('AppLocalizations.of returns Arabic strings for ar locale',
        (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const _LocaleProbe(),
          locale: const Locale('ar', 'MA'),
        ),
      );

      expect(find.text('دوستك'), findsOneWidget);
    });

    testWidgets('AppLocalizations.of returns English strings for en locale',
        (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const _LocaleProbe(),
          locale: const Locale('en'),
        ),
      );

      expect(find.text('Dostok'), findsOneWidget);
    });
  });

  // =========================================================================
  // ChatBubble tests
  // =========================================================================

  group('ChatBubble', () {
    testWidgets('renders user message aligned right with teal background',
        (tester) async {
      final message = _testMessage(isFromUser: true, content: 'بسلامة!');

      await tester.pumpWidget(buildTestable(ChatBubble(message: message)));
      await tester.pumpAndSettle();

      // The message text should appear.
      expect(find.text('بسلامة!'), findsOneWidget);

      // User bubbles are right-aligned.
      final align = tester.widget<Align>(find.byType(Align).last);
      expect(align.alignment, Alignment.centerRight);
    });

    testWidgets('renders AI message aligned left', (tester) async {
      final message = _testMessage(
        id: 'test-002',
        isFromUser: false,
        content: 'مرحبا صاحبي!',
      );

      await tester.pumpWidget(buildTestable(ChatBubble(message: message)));
      await tester.pumpAndSettle();

      expect(find.text('مرحبا صاحبي!'), findsOneWidget);

      final align = tester.widget<Align>(find.byType(Align).last);
      expect(align.alignment, Alignment.centerLeft);
    });

    testWidgets('renders system message as centered muted caption',
        (tester) async {
      final message = _testMessage(
        id: 'test-003',
        isFromUser: false,
        content: 'بداية المحادثة',
        type: MessageType.system,
      );

      await tester.pumpWidget(buildTestable(ChatBubble(message: message)));
      await tester.pumpAndSettle();

      expect(find.text('بداية المحادثة'), findsOneWidget);

      // System messages are rendered inside a Center widget.
      expect(find.byType(Center), findsWidgets);
    });

    testWidgets('shows read receipt icons for user messages', (tester) async {
      final unread = _testMessage(isRead: false);
      final read = _testMessage(id: 'test-004', isRead: true);

      // Unread -- single check.
      await tester.pumpWidget(buildTestable(ChatBubble(message: unread)));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.done), findsOneWidget);

      // Read -- double check.
      await tester.pumpWidget(buildTestable(ChatBubble(message: read)));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.done_all), findsOneWidget);
    });

    testWidgets('displays timestamp in HH:mm format', (tester) async {
      final message = _testMessage();

      await tester.pumpWidget(buildTestable(ChatBubble(message: message)));
      await tester.pumpAndSettle();

      // 14:30
      expect(find.text('14:30'), findsOneWidget);
    });

    testWidgets('long-press copies text and shows snackbar', (tester) async {
      final message = _testMessage(content: 'نص للنسخ');

      await tester.pumpWidget(buildTestable(ChatBubble(message: message)));
      await tester.pumpAndSettle();

      // Long-press the message.
      await tester.longPress(find.text('نص للنسخ'));
      await tester.pumpAndSettle();

      // A snackbar should appear with the copy confirmation.
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });

  // =========================================================================
  // LoadingWidget tests
  // =========================================================================

  group('LoadingWidget', () {
    testWidgets('shows CircularProgressIndicator', (tester) async {
      await tester.pumpWidget(buildTestable(const LoadingWidget()));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays the first loading message', (tester) async {
      await tester.pumpWidget(buildTestable(const LoadingWidget()));
      await tester.pump();

      // The default messages include this string.
      expect(find.text('شوية ديال الصبر...'), findsOneWidget);
    });

    testWidgets('rotates to the next message after duration', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const LoadingWidget(
            messageDuration: Duration(milliseconds: 500),
          ),
        ),
      );
      await tester.pump();

      // First message visible.
      expect(find.text('شوية ديال الصبر...'), findsOneWidget);

      // Advance past the rotation point.
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // A different message should now be shown.
      expect(find.text('كنتسنّى...'), findsOneWidget);
    });

    testWidgets('accepts custom messages', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const LoadingWidget(
            messages: ['كنحضّر...', 'تقريبا وجدت...'],
          ),
        ),
      );
      await tester.pump();

      expect(find.text('كنحضّر...'), findsOneWidget);
    });
  });

  // =========================================================================
  // AppErrorWidget tests
  // =========================================================================

  group('AppErrorWidget', () {
    testWidgets('renders default Darija error message', (tester) async {
      await tester.pumpWidget(buildTestable(const AppErrorWidget()));

      expect(find.text('واحد المشكيل!'), findsOneWidget);
      expect(find.text('وقع شي مشكيل، عاود جرب مرة أخرى'), findsOneWidget);
    });

    testWidgets('shows retry button when onRetry is provided', (tester) async {
      var retried = false;

      await tester.pumpWidget(
        buildTestable(
          AppErrorWidget(onRetry: () => retried = true),
        ),
      );

      // Retry button exists.
      expect(find.text('عاود جرب'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);

      // Tap it.
      await tester.tap(find.text('عاود جرب'));
      await tester.pump();

      expect(retried, isTrue);
    });

    testWidgets('hides retry button when onRetry is null', (tester) async {
      await tester.pumpWidget(buildTestable(const AppErrorWidget()));

      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('renders custom icon and message', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const AppErrorWidget(
            icon: Icons.wifi_off_rounded,
            title: 'مكاينش الأنترنت',
            message: 'تأكد من الكونيكسيون ديالك',
          ),
        ),
      );

      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
      expect(find.text('مكاينش الأنترنت'), findsOneWidget);
      expect(find.text('تأكد من الكونيكسيون ديالك'), findsOneWidget);
    });

    testWidgets('shows dismiss button when showDismiss is true',
        (tester) async {
      var dismissed = false;

      await tester.pumpWidget(
        buildTestable(
          AppErrorWidget(
            showDismiss: true,
            onDismiss: () => dismissed = true,
          ),
        ),
      );

      expect(find.text('سدّ'), findsOneWidget);

      await tester.tap(find.text('سدّ'));
      await tester.pump();

      expect(dismissed, isTrue);
    });
  });

  // =========================================================================
  // InlineErrorBanner tests
  // =========================================================================

  group('InlineErrorBanner', () {
    testWidgets('renders message text', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const InlineErrorBanner(message: 'مشكيل ف الأنترنت'),
        ),
      );

      expect(find.text('مشكيل ف الأنترنت'), findsOneWidget);
    });

    testWidgets('shows retry link when onRetry is provided', (tester) async {
      var retried = false;

      await tester.pumpWidget(
        buildTestable(
          InlineErrorBanner(
            message: 'مشكيل',
            onRetry: () => retried = true,
          ),
        ),
      );

      expect(find.text('عاود جرب'), findsOneWidget);

      await tester.tap(find.text('عاود جرب'));
      await tester.pump();

      expect(retried, isTrue);
    });
  });

  // =========================================================================
  // EmptyState tests
  // =========================================================================

  group('EmptyState', () {
    testWidgets('renders default icon and title', (tester) async {
      await tester.pumpWidget(buildTestable(const EmptyState()));

      expect(find.byIcon(Icons.waving_hand_rounded), findsOneWidget);
      expect(find.text('والو هنا'), findsOneWidget);
    });

    testWidgets('shows action button when onAction is provided', (tester) async {
      var acted = false;

      await tester.pumpWidget(
        buildTestable(
          EmptyState(onAction: () => acted = true),
        ),
      );

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('بدا هضرة دابا'), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(acted, isTrue);
    });

    testWidgets('hides action button when onAction is null', (tester) async {
      await tester.pumpWidget(buildTestable(const EmptyState()));

      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('renders custom icon, title, message, and action label',
        (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const EmptyState(
            icon: Icons.task_alt_rounded,
            title: 'ما زال شي واجب',
            message: 'زيد شي حاجة',
            actionLabel: 'زيد واجب',
          ),
        ),
      );

      expect(find.byIcon(Icons.task_alt_rounded), findsOneWidget);
      expect(find.text('ما زال شي واجب'), findsOneWidget);
      expect(find.text('زيد شي حاجة'), findsOneWidget);
      expect(find.text('زيد واجب'), findsOneWidget);
    });

    testWidgets('presets: messages() renders correct Darija copy',
        (tester) async {
      await tester.pumpWidget(
        buildTestable(EmptyState.messages()),
      );

      expect(find.text('ما زال ما هضرنا!'), findsOneWidget);
      expect(find.text('بدا هضرة معايا و غادي نكون صاحبك'), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);
    });

    testWidgets('presets: tasks() renders correct Darija copy', (tester) async {
      await tester.pumpWidget(
        buildTestable(EmptyState.tasks()),
      );

      expect(find.text('ما زال ما ديرتي شي واجب'), findsOneWidget);
      expect(find.byIcon(Icons.task_alt_rounded), findsOneWidget);
    });
  });
}

// ---------------------------------------------------------------------------
// Locale probe widget
// ---------------------------------------------------------------------------

/// Tiny widget that reads [AppLocalizations] and displays the app name.
/// Used to verify the delegate wiring.
class _LocaleProbe extends StatelessWidget {
  const _LocaleProbe();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Text(l10n.appName);
  }
}
