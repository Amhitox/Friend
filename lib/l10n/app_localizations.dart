import 'package:flutter/material.dart';

/// Simple localization class for the Dostok app.
///
/// Provides locale-aware strings for Moroccan Arabic (Darija) and English.
/// Uses a static [of] method to retrieve the nearest [AppLocalizations]
/// instance from the widget tree via [Localizations.of].
///
/// For a production app you would generate these with `flutter gen-l10n` and
/// ARB files. This lightweight implementation keeps things self-contained
/// without build-runner or intl codegen.
///
/// Usage:
/// ```dart
/// final l10n = AppLocalizations.of(context);
/// Text(l10n.appName); // "دوستك" or "Dostok"
/// ```
class AppLocalizations {
  /// The locale this instance was created for.
  final Locale locale;

  const AppLocalizations(this.locale);

  /// Returns the [AppLocalizations] closest to the given [context].
  ///
  /// Throws if no [AppLocalizations] ancestor is found. Wrap your app with
  /// [AppLocalizations.delegate] in `MaterialApp.localizationsDelegates`.
  static AppLocalizations of(BuildContext context) {
    final localizations = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    assert(localizations != null, 'No AppLocalizations found in context');
    return localizations!;
  }

  /// Whether the current locale is a variant of Arabic.
  bool get isArabic => locale.languageCode == 'ar';

  /// Whether the text direction should be RTL.
  bool get isRtl => isArabic;

  // ===========================================================================
  // String maps
  // ===========================================================================

  static const Map<String, Map<String, String>> _localizedStrings = {
    'ar': {
      // App identity
      'appName': 'دوستك',
      'appTagline': 'أنا دوستك، صاحبك',

      // Common buttons
      'buttonRetry': 'عاود جرب',
      'buttonCancel': 'لغي',
      'buttonSave': 'حفظ',
      'buttonDone': 'تمام',
      'buttonNext': 'التالي',
      'buttonDelete': 'مسح',
      'buttonClose': 'سدّ',
      'buttonLetsGo': 'يلاه نبداو!',

      // Loading
      'loading': 'كنتسنّى...',
      'loadingMessages': 'شوية ديال الصبر...',
      'loadingAlmostReady': 'تقريبا وجدت...',
      'loadingThinking': 'كنفكر شنو نقول ليك...',
      'loadingPreparing': 'كنحضّر ليك شي حاجة زوينة...',

      // Error states
      'errorGenericTitle': 'واحد المشكيل!',
      'errorGenericDesc': 'وقع شي مشكيل، عاود جرب مرة أخرى',
      'errorNoInternet': 'مكاينش الأنترنت',
      'errorSomethingWrong': 'وقع شي حاجة غلط، سمح ليا',
      'errorTimeout': 'تاخد وقت بزاف، عاود جرب',
      'errorServer': 'السيرفر ما كايجاوبش دابا',

      // Empty states
      'emptyTitle': 'والو هنا',
      'emptyMessagesTitle': 'ما زال ما هضرنا!',
      'emptyMessagesDesc': 'بدا هضرة معايا و غادي نكون صاحبك',
      'emptyTasksTitle': 'ما زال ما ديرتي شي واجب',
      'emptyTasksDesc': 'زيد شي واجب باش نعاونك نتتبعو',
      'emptyStartButton': 'بدا هضرة دابا',
      'emptyAddButton': 'زيد حاجة',

      // Greetings
      'greetingMorning': 'صباح الخير',
      'greetingAfternoon': 'مساء الخير',
      'greetingEvening': 'ليلة سعيدة',
      'greetingCasual': 'سلام! لاباس عليك؟',
      'greetingWelcomeBack': 'أهلاً بيك!',

      // Chat
      'chatPlaceholder': 'كتب ليا...',
      'chatThinking': 'كنفكر...',
      'chatListening': 'كنسمعك...',
      'chatSend': 'صيفط',
      'chatSendError': 'ما قدرتش نصيفط، عاود جرب',

      // Navigation
      'navHome': 'لقط ديالي',
      'navDaily': 'نهار ديالي',
      'navProfile': 'بروفيل',

      // Confirmation
      'confirmYes': 'اه',
      'confirmNo': 'لا',
      'confirmAreYouSure': 'نتأكد؟',
    },
    'en': {
      // App identity
      'appName': 'Dostok',
      'appTagline': "I'm Dostok, your friend",

      // Common buttons
      'buttonRetry': 'Try again',
      'buttonCancel': 'Cancel',
      'buttonSave': 'Save',
      'buttonDone': 'Done',
      'buttonNext': 'Next',
      'buttonDelete': 'Delete',
      'buttonClose': 'Close',
      'buttonLetsGo': "Let's go!",

      // Loading
      'loading': 'Loading...',
      'loadingMessages': 'Just a moment...',
      'loadingAlmostReady': 'Almost ready...',
      'loadingThinking': 'Thinking of what to say...',
      'loadingPreparing': 'Preparing something nice for you...',

      // Error states
      'errorGenericTitle': 'Oops!',
      'errorGenericDesc': 'Something went wrong. Please try again.',
      'errorNoInternet': 'No internet connection',
      'errorSomethingWrong': 'Something went wrong, sorry!',
      'errorTimeout': 'It took too long. Please try again.',
      'errorServer': 'The server is not responding right now',

      // Empty states
      'emptyTitle': 'Nothing here',
      'emptyMessagesTitle': "We haven't talked yet!",
      'emptyMessagesDesc': 'Start a conversation and we can be friends',
      'emptyTasksTitle': 'No tasks yet',
      'emptyTasksDesc': 'Add a task so I can help you track it',
      'emptyStartButton': 'Start chatting now',
      'emptyAddButton': 'Add something',

      // Greetings
      'greetingMorning': 'Good morning',
      'greetingAfternoon': 'Good afternoon',
      'greetingEvening': 'Good evening',
      'greetingCasual': 'Hey! How are you?',
      'greetingWelcomeBack': 'Welcome back!',

      // Chat
      'chatPlaceholder': 'Write something...',
      'chatThinking': 'Thinking...',
      'chatListening': 'Listening...',
      'chatSend': 'Send',
      'chatSendError': "Couldn't send. Please try again.",

      // Navigation
      'navHome': 'Home',
      'navDaily': 'My Day',
      'navProfile': 'Profile',

      // Confirmation
      'confirmYes': 'Yes',
      'confirmNo': 'No',
      'confirmAreYouSure': 'Are you sure?',
    },
  };

  // ===========================================================================
  // Typed accessors
  //
  // Each getter looks up the key in the current locale's map, falling back
  // to English if the key is missing.
  // ===========================================================================

  String _get(String key) {
    final lang = locale.languageCode;
    return _localizedStrings[lang]?[key] ??
        _localizedStrings['en']?[key] ??
        key;
  }

  // -- App identity -----------------------------------------------------------

  String get appName => _get('appName');
  String get appTagline => _get('appTagline');

  // -- Common buttons ---------------------------------------------------------

  String get buttonRetry => _get('buttonRetry');
  String get buttonCancel => _get('buttonCancel');
  String get buttonSave => _get('buttonSave');
  String get buttonDone => _get('buttonDone');
  String get buttonNext => _get('buttonNext');
  String get buttonDelete => _get('buttonDelete');
  String get buttonClose => _get('buttonClose');
  String get buttonLetsGo => _get('buttonLetsGo');

  // -- Loading ----------------------------------------------------------------

  String get loading => _get('loading');
  String get loadingMessages => _get('loadingMessages');
  String get loadingAlmostReady => _get('loadingAlmostReady');
  String get loadingThinking => _get('loadingThinking');
  String get loadingPreparing => _get('loadingPreparing');

  // -- Error states -----------------------------------------------------------

  String get errorGenericTitle => _get('errorGenericTitle');
  String get errorGenericDesc => _get('errorGenericDesc');
  String get errorNoInternet => _get('errorNoInternet');
  String get errorSomethingWrong => _get('errorSomethingWrong');
  String get errorTimeout => _get('errorTimeout');
  String get errorServer => _get('errorServer');

  // -- Empty states -----------------------------------------------------------

  String get emptyTitle => _get('emptyTitle');
  String get emptyMessagesTitle => _get('emptyMessagesTitle');
  String get emptyMessagesDesc => _get('emptyMessagesDesc');
  String get emptyTasksTitle => _get('emptyTasksTitle');
  String get emptyTasksDesc => _get('emptyTasksDesc');
  String get emptyStartButton => _get('emptyStartButton');
  String get emptyAddButton => _get('emptyAddButton');

  // -- Greetings --------------------------------------------------------------

  String get greetingMorning => _get('greetingMorning');
  String get greetingAfternoon => _get('greetingAfternoon');
  String get greetingEvening => _get('greetingEvening');
  String get greetingCasual => _get('greetingCasual');
  String get greetingWelcomeBack => _get('greetingWelcomeBack');

  // -- Chat -------------------------------------------------------------------

  String get chatPlaceholder => _get('chatPlaceholder');
  String get chatThinking => _get('chatThinking');
  String get chatListening => _get('chatListening');
  String get chatSend => _get('chatSend');
  String get chatSendError => _get('chatSendError');

  // -- Navigation -------------------------------------------------------------

  String get navHome => _get('navHome');
  String get navDaily => _get('navDaily');
  String get navProfile => _get('navProfile');

  // -- Confirmation -----------------------------------------------------------

  String get confirmYes => _get('confirmYes');
  String get confirmNo => _get('confirmNo');
  String get confirmAreYouSure => _get('confirmAreYouSure');
}

/// [LocalizationsDelegate] that loads [AppLocalizations] for the given locale.
///
/// Register this in `MaterialApp.localizationsDelegates`:
/// ```dart
/// localizationsDelegates: [
///   AppLocalizations.delegate,
///   GlobalMaterialLocalizations.delegate,
///   GlobalWidgetsLocalizations.delegate,
/// ],
/// supportedLocales: AppLocalizations.supportedLocales,
/// ```
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  /// The locales the app fully supports.
  static const List<Locale> supportedLocales = [
    Locale('ar', 'MA'),
    Locale('ar'),
    Locale('en'),
  ];

  @override
  bool isSupported(Locale locale) {
    return supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}
