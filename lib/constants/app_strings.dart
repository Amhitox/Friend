/// All user-facing UI strings for the Dostok app, written in Moroccan Darija
/// (Arabic script).
///
/// Strings are grouped by screen or feature. Transliteration comments are
/// provided in parentheses to help non-Arabic-reading developers understand
/// what each string means. The app name "Dostok" (دوستك) means "your friend"
/// in Darija.
///
/// Usage:
/// ```dart
/// Text(AppStrings.greetingMorning); // صباح الخير
/// ```
abstract final class AppStrings {
  // ===========================================================================
  // App Identity
  // ===========================================================================

  /// App display name. (Dostok = "your friend")
  static const String appName = 'دوستك';

  /// App tagline shown on splash. (Ana Dostok, sahibek = "I'm Dostok, your friend")
  static const String appTagline = 'أنا دوستك، صاحبك';

  // ===========================================================================
  // Greetings (time-based)
  // ===========================================================================

  /// Morning greeting, roughly 5am-12pm. (Sabah l-kher = "good morning")
  static const String greetingMorning = 'صباح الخير';

  /// Afternoon greeting, roughly 12pm-6pm. (Msa l-kher = "good afternoon/evening")
  static const String greetingAfternoon = 'مساء الخير';

  /// Evening/night greeting, after 6pm. (Lila sa3ida = "good night/happy evening")
  static const String greetingEvening = 'ليلة سعيدة';

  /// Generic casual greeting. (Salam! Labas 3lik? = "Hi! How are you?")
  static const String greetingCasual = 'سلام! لاباس عليك؟';

  /// Warm return greeting. (Ahlan bik! = "Welcome back!")
  static const String greetingWelcomeBack = 'أهلاً بيك!';

  // ===========================================================================
  // Home Screen
  // ===========================================================================

  /// "What do you want to do today?"
  static const String homeQuestion = 'شنو بغيتي دير اليوم؟';

  /// Section title: "What do you need?"
  static const String homeWhatDoYouNeed = 'شنو بغيتي؟';

  /// Section title: "Recent conversations"
  static const String homeRecentConversations = 'هضرة غير دازت';

  /// Empty state: "Haven't chatted with Dostok yet"
  static const String homeNoConversations = 'ما زال ما هضرتي مع دوستك!';

  /// CTA to start chatting. (Bda hadra daba = "Start talking now")
  static const String homeStartChat = 'بدا هضرة دابا';

  /// Relationship label. (M3a Dostok = "With Dostok")
  static const String homeRelationshipLabel = 'مع دوستك';

  /// Days active label. (Nhar = "day/days")
  static const String homeDaysUnit = 'نهار';

  // ===========================================================================
  // Quick Action Cards
  // ===========================================================================

  /// "Talk to me" -- chat action.
  static const String actionChat = 'هضر معايا';

  /// "In Darija now" -- chat subtitle.
  static const String actionChatSubtitle = 'بالدارجة دابا';

  /// "What's today?" -- daily feature.
  static const String actionDaily = 'شنو اليوم؟';

  /// "Daily idea" -- daily subtitle.
  static const String actionDailySubtitle = 'فكرة يومية';

  /// "Help me" -- learning/help action.
  static const String actionHelp = 'عاوني';

  /// "New thing" -- help subtitle.
  static const String actionHelpSubtitle = 'معلومة جديدة';

  // ===========================================================================
  // Bottom Navigation
  // ===========================================================================

  /// Home tab label. (Lqt diali = "My place")
  static const String navHome = 'لقط ديالي';

  /// Daily tab label. (Nhar diali = "My day")
  static const String navDaily = 'نهار ديالي';

  /// Profile tab label.
  static const String navProfile = 'بروفيل';

  // ===========================================================================
  // Chat Screen
  // ===========================================================================

  /// Chat screen title.
  static const String chatTitle = 'هضرة مع دوستك';

  /// Input placeholder. (Ktb liya... = "Write to me...")
  static const String chatPlaceholder = 'كتب ليا...';

  /// "Listening..." state during voice input.
  static const String chatListening = 'كنسمعك...';

  /// "Thinking..." while AI generates response.
  static const String chatThinking = 'كنفكر...';

  /// "Send" button label.
  static const String chatSend = 'صيفط';

  /// "Voice message" tooltip.
  static const String chatVoiceTooltip = 'رسالة صوتية';

  /// Error when message fails to send. (Maqderch nsift = "Couldn't send")
  static const String chatSendError = 'ما قدرتش نصيفط، عاود جرب';

  /// Network error. (Mchkil f l'internet = "Internet problem")
  static const String chatNetworkError = 'مشكيل ف الأنترنت، تأكد من الكونيكسيون';

  // ===========================================================================
  // Call Screen
  // ===========================================================================

  /// Call screen title. (Kallem m3ak = "Talk with you")
  static const String callTitle = 'كالم معاك';

  /// "Calling Dostok..." state.
  static const String callConnecting = 'كنصيفط لدوستك...';

  /// "Connected, speak now" state.
  static const String callConnected = ' واصلة، هضر دابا';

  /// "Tap to end" call.
  static const String callEnd = 'أنهي المكالمة';

  /// "Tap to start" call.
  static const String callStart = 'بدا مكالمة';

  /// Call duration label. (Modda = "duration")
  static const String callDuration = 'المدة';

  /// Permission needed for mic. (Khassek microphone = "You need mic access")
  static const String callMicPermission =
      'خاصك تفعّل الميكروفون باش نقدرو نهضرو';

  // ===========================================================================
  // Daily / Mood
  // ===========================================================================

  /// Section title: "My Day".
  static const String dailyTitle = 'نهار ديالي';

  /// "How are you today?"
  static const String dailyHowAreYou = 'كيف داير اليوم؟';

  /// "What's your mood?"
  static const String dailyMoodQuestion = 'شنو mood ديالك؟';

  /// Mood labels
  static const String moodHappy = 'منيتش';
  static const String moodExcited = 'متحمس';
  static const String moodTired = 'تعبان';
  static const String moodNeutral = 'عادي';
  static const String moodAnxious = 'معصاب';
  static const String moodSad = 'حزين';

  /// Section title: "Daily tasks".
  static const String dailyTasks = 'واجبات يومية';

  /// "Add task" button.
  static const String dailyAddTask = 'زيد واجب';

  /// "Add new task" dialog title.
  static const String dailyAddTaskTitle = 'زيد واجب جديد';

  /// Task input placeholder. (Ktb wajb dyalek = "Write your task")
  static const String dailyTaskHint = 'كتب واجب ديالك...';

  /// "Cancel" button.
  static const String buttonCancel = 'لغي';

  /// "Add" button.
  static const String buttonAdd = 'زيد';

  /// Empty state: "No tasks yet today".
  static const String dailyNoTasks = 'ما زال ما ديرتي شي واجب اليوم';

  /// Section title: "Motivational quote".
  static const String dailyQuoteTitle = 'كلمة تحفيزية';

  // ===========================================================================
  // Onboarding
  // ===========================================================================

  /// Skip button. (Tkhatta = "Skip")
  static const String onboardingSkip = 'تخطّى';

  /// Welcome heading. (Mar7ba! Ana dostok = "Hello! I'm Dostok")
  static const String onboardingWelcome = 'مرحبا! أنا دوستك';

  /// Welcome subtitle. (Ana Dostok, sahibek l-jdid = "I'm Dostok, your new friend")
  static const String onboardingWelcomeSubtitle = 'أنا دوستك، صاحبك الجديد!';

  /// Welcome description. (Ghadi nkun m3ak f kul nhar = "I'll be with you every day")
  static const String onboardingWelcomeDesc =
      'غادي نكون معاك فكل يوم، نهضرو ونتسناو معاك';

  /// Language page heading. (Kanhdro b Darija = "We speak Darija")
  static const String onboardingLanguageTitle = 'كنهضرو بالدارجة';

  /// Language page description.
  static const String onboardingLanguageDesc =
      'كنهضرو بالدارجة المغربية، كيف كتهضر مع صحابك';

  /// Language feature: "Natural Darija".
  static const String onboardingLangNatural = 'دارجة طبيعية';

  /// Language feature: "Expressions in Darija".
  static const String onboardingLangExpressions = 'تعبيرات بالدارجة';

  /// Language feature: "Understands your context".
  static const String onboardingLangContext = 'كاي فهم ليك السياق ديالك';

  /// Friend page heading. (Sadiqek = "Your friend")
  static const String onboardingFriendTitle = 'صديقك';

  /// Friend page subtitle. (Sahibek, machi mutajarrab app = "Your friend, not just an app")
  static const String onboardingFriendSubtitle = 'صاحبك، ماشي مجرد تطبيق';

  /// Feature: voice calls.
  static const String onboardingFriendCallTitle = 'كالم معاك';

  /// Feature: voice calls description.
  static const String onboardingFriendCallDesc =
      'هضرو و كالم معايا بصوتك';

  /// Feature: celebrations.
  static const String onboardingFriendCelebrateTitle = 'فرّح معاك';

  /// Feature: celebrations description.
  static const String onboardingFriendCelebrateDesc =
      'كنفرحك و نعاونك نهارك يدوز مزيان';

  /// Feature: learning.
  static const String onboardingFriendLearnTitle = 'علّمك';

  /// Feature: learning description.
  static const String onboardingFriendLearnDesc =
      'كنعلمك حوايج جداد كل نهار';

  /// Setup page heading. (Khallina nbaddaw! = "Let's get started!")
  static const String onboardingSetupTitle = 'خلّينا نبداو!';

  /// Setup page: "What's your name?"
  static const String onboardingNameQuestion = 'شنو سميتك؟';

  /// Name input placeholder.
  static const String onboardingNameHint = '...';

  /// Setup helper text.
  static const String onboardingNameHelper =
      'هادشي غادي يعاونّي نعرفك مزيان';

  /// Name validation error. (Dkhel smiytek, 3afak = "Enter your name, please")
  static const String onboardingNameError = 'دخل سميتك، عافاك';

  /// "Next" button.
  static const String buttonNext = 'التالي';

  /// "Let's go!" button on final onboarding page. (Yallah nbaddaw! = "Let's go!")
  static const String buttonLetsGo = 'يلاه نبداو!';

  // ===========================================================================
  // Profile Screen
  // ===========================================================================

  /// Profile screen title.
  static const String profileTitle = 'بروفيل ديالي';

  /// Edit profile button.
  static const String profileEdit = 'عدّل بروفيل';

  /// "Days together" stat label.
  static const String profileDaysTogether = 'نهار مع بعض';

  /// "Messages exchanged" stat label.
  static const String profileMessages = 'رسائل تبادلناها';

  /// "Relationship level" label.
  static const String profileRelationship = 'مستوى الصداقة';

  /// Relationship titles by level.
  static const String relationshipNew = 'صاحب جديد';
  static const String relationshipAcquaintance = 'صاحب معرفة';
  static const String relationshipClose = 'صاحب قريب';
  static const String relationshipBestFriend = 'صاحب عمري';

  // ===========================================================================
  // Settings
  // ===========================================================================

  /// Settings screen title.
  static const String settingsTitle = 'الإعدادات';

  /// Theme toggle label. (Mode = "Mode")
  static const String settingsTheme = 'الوضع';

  /// Light theme label.
  static const String settingsThemeLight = 'فاتح';

  /// Dark theme label.
  static const String settingsThemeDark = 'داكن';

  /// System theme label. (System = "System")
  static const String settingsThemeSystem = 'تلقائي';

  /// Language setting label.
  static const String settingsLanguage = 'اللغة';

  // ===========================================================================
  // Error & Empty States
  // ===========================================================================

  /// Generic error title. (Wa7 l-mochkil! = "There's a problem!")
  static const String errorGenericTitle = 'واحد المشكيل!';

  /// Generic error description.
  static const String errorGenericDesc =
      'وقع شي مشكيل، عاود جرب مرة أخرى';

  /// No internet error. (Makaynch internet = "No internet")
  static const String errorNoInternet = 'مكاينش الأنترنت';

  /// Retry button. (3awed jareb = "Try again")
  static const String buttonRetry = 'عاود جرب';

  /// "Something went wrong" fallback.
  static const String errorSomethingWrong = 'وقع شي حاجة غلط، سمح ليا';

  // ===========================================================================
  // Miscellaneous
  // ===========================================================================

  /// Loading indicator text. (Kantssenna... = "Loading...")
  static const String loading = 'كنتسنّى...';

  /// "Save" button.
  static const String buttonSave = 'حفظ';

  /// "Done" / "Finished" button.
  static const String buttonDone = 'تمام';

  /// "Delete" button.
  static const String buttonDelete = 'مسح';

  /// "Edit" button.
  static const String buttonEdit = 'عدّل';

  /// "Close" button.
  static const String buttonClose = 'سدّ';

  /// "Yes" confirmation.
  static const String confirmYes = 'اه';

  /// "No" confirmation.
  static const String confirmNo = 'لا';

  /// "Are you sure?" confirmation prompt.
  static const String confirmAreYouSure = 'نتأكد؟';
}
