import 'dart:developer' as dev;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

/// Manages the user's daily briefing: mood tracking, task list, and a
/// Darija motivational quote.
///
/// Persisted via Hive so the daily state survives app restarts. Widgets
/// consume this provider to render the home-screen greeting card.
class DailyProvider extends ChangeNotifier {
  static const String _boxName = 'settings';
  static const String _moodKey = 'todaysMood';
  static const String _tasksKey = 'dailyTasks';
  static const String _quoteKey = 'dailyQuote';
  static const String _quoteDateKey = 'dailyQuoteDate';
  static const String _moodDateKey = 'moodDate';

  static final Random _random = Random();

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  String? _todaysMood;
  List<String> _tasks = [];
  String? _motivationalQuote;
  bool _isLoading = false;
  String? _error;

  // ---------------------------------------------------------------------------
  // Darija motivational quotes collection
  // ---------------------------------------------------------------------------

  /// A curated collection of motivational phrases in Moroccan Darija with
  /// approximate transliterations and translations.
  static const List<Map<String, String>> _darijaQuotes = [
    {
      'darija': 'اللي بغا يوصل، كيلاقي طريقة.',
      'transliteration': 'Li bgha ywssel, kilayqi tri9a.',
      'translation': 'Whoever wants to find a way.',
    },
    {
      'darija': 'صبري عليا نصبر عليك، نلقاو الحياة زوينة.',
      'transliteration': 'Sabri 3liya nsabr 3lik, nlqaw l7ayat zwina.',
      'translation': 'Be patient with me, I\'ll be patient with you, and life will be beautiful.',
    },
    {
      'darija': 'كل نهار بداية جديدة.',
      'transliteration': 'Kul nhar bidaya jdida.',
      'translation': 'Every day is a new beginning.',
    },
    {
      'darija': 'اللي ما كيخافش يطيح، ما كيوصلش لفوق.',
      'transliteration': 'Li ma kikhafsh yti7, ma kiwsslsh lfo9.',
      'translation': 'Those who aren\'t afraid to fall won\'t reach the top.',
    },
    {
      'darija': 'سير لقدام و ما ت回头看.',
      'transliteration': 'Sir l9dam w ma ttfrrj lura.',
      'translation': 'Keep moving forward, don\'t look back.',
    },
    {
      'darija': 'خدمة اليوم هي فرحة الغد.',
      'transliteration': 'Khdamat lyoum hiya far7at lghod.',
      'translation': 'Today\'s work is tomorrow\'s joy.',
    },
    {
      'darija': 'اللي عندو هدف، كيلقى طريقة.',
      'transliteration': 'Li 3ndou hadaf, kilayqi tri9a.',
      'translation': 'Those with a goal find a path.',
    },
    {
      'darija': 'ما تقولش ما نقدرش، قول نجرب.',
      'transliteration': 'Ma tqolsh ma n9dersh, qoul njarrab.',
      'translation': 'Don\'t say I can\'t, say I\'ll try.',
    },
    {
      'darija': 'ابدأ بصغير، تحلم بكبير.',
      'transliteration': 'Ibda bssghir, t7allam bkbir.',
      'translation': 'Start small, dream big.',
    },
    {
      'darija': 'كل خطوة كتقرّبك من حلمك.',
      'transliteration': 'Kul khtwa kt9arrbek mn 7olmok.',
      'translation': 'Every step brings you closer to your dream.',
    },
    {
      'darija': 'الفرح كيجي بعد الصبر.',
      'transliteration': 'Lfar7 kiji b3d ssabr.',
      'translation': 'Happiness comes after patience.',
    },
    {
      'darija': 'ثيق فراسك، نتا أقوى مما تظن.',
      'transliteration': 'Thi9 frasak, nta a9wa mma tḍonn.',
      'translation': 'Believe in yourself, you\'re stronger than you think.',
    },
    {
      'darija': 'اليوم هو هدية، و هو سميتو presente.',
      'transliteration': 'Lyoum howa hdiya, w howa smiytou present.',
      'translation': 'Today is a gift, that\'s why it\'s called the present.',
    },
    {
      'darija': 'ما كاين لاش تبكي على اللي فات، ضحك على اللي جاي.',
      'transliteration': 'Ma kayn lash tbki 3la li fat, d77k 3la li jay.',
      'translation': 'No need to cry over the past, laugh at what\'s coming.',
    },
    {
      'darija': 'النجاح بدا من هنا، من هاد اللحظة.',
      'transliteration': 'Nnaja7 bda mn hna, mn had lla7da.',
      'translation': 'Success starts here, from this moment.',
    },
    {
      'darija': 'الدنيا قصيرة، عيشها بفرحة.',
      'transliteration': 'Ddunya 9sira, 3iyshha bfar7a.',
      'translation': 'Life is short, live it with joy.',
    },
    {
      'darija': 'حتى حاجة ساهلة، و لكن كلشي ممكن.',
      'transliteration': '7tta 7aja sahla, w lakin kulshi mumkin.',
      'translation': 'Nothing is easy, but everything is possible.',
    },
    {
      'darija': 'خلي optimisme ديالك يفوق.',
      'transliteration': 'Khalli optimisme dyalek yfo9.',
      'translation': 'Let your optimism shine.',
    },
    {
      'darija': 'كل يوم معاك هو نعمة.',
      'transliteration': 'Kul youm m3ak howa n3ima.',
      'translation': 'Every day with you is a blessing.',
    },
    {
      'darija': 'كمل طريقك، الصبر مفتاح الفرج.',
      'transliteration': 'Kammal tri9ek, ssabr mfta7 lfaraj.',
      'translation': 'Continue your path, patience is the key to relief.',
    },
    {
      'darija': 'دير اللي عليك و توكل على الله.',
      'transliteration': 'Dir li 3lik w tawakkal 3la Allah.',
      'translation': 'Do your best and trust in God.',
    },
    {
      'darija': 'اللي تعلّم من غلطاتو، هو اللي كيكبر.',
      'transliteration': 'Li t3allam mn ghaltatou, howa li kikbar.',
      'translation': 'The one who learns from mistakes is the one who grows.',
    },
    {
      'darija': 'ما كاين مستحيل، كاين غير ما بغيتيش.',
      'transliteration': 'Ma kayn msta7il, kayn ghir ma bghitish.',
      'translation': 'Nothing is impossible, you just didn\'t want it enough.',
    },
    {
      'darija': 'ابتسامتك هي أجمل حاجة فيك.',
      'transliteration': 'Ibtisamtk hiya ajmal 7aja fik.',
      'translation': 'Your smile is the most beautiful thing about you.',
    },
    {
      'darija': 'غدا أحسن من اليوم، ديما.',
      'transliteration': 'Ghda a7san mn lyoum, dima.',
      'translation': 'Tomorrow is always better than today.',
    },
  ];

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  /// The mood emoji or label the user selected today, if any.
  String? get todaysMood => _todaysMood;

  /// The user's task list for today.
  List<String> get tasks => List.unmodifiable(_tasks);

  /// Number of completed (checked-off) tasks.
  int get completedTaskCount => _tasks.where((t) => t.startsWith('[x]')).length;

  /// Total number of tasks.
  int get totalTaskCount => _tasks.length;

  /// Whether all tasks are completed.
  bool get allTasksDone => _tasks.isNotEmpty && _tasks.every((t) => t.startsWith('[x]'));

  /// Today's motivational Darija quote.
  String? get motivationalQuote => _motivationalQuote;

  /// Whether data is loading.
  bool get isLoading => _isLoading;

  /// The last error message, if any.
  String? get error => _error;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Loads persisted daily data from Hive. Call once during app startup.
  Future<void> loadDailyData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final box = await Hive.openBox(_boxName);

      // Load mood (only if it's from today).
      final moodDateStr = box.get(_moodDateKey) as String?;
      if (moodDateStr != null) {
        final moodDate = DateTime.tryParse(moodDateStr);
        if (moodDate != null && _isSameDay(moodDate, DateTime.now())) {
          _todaysMood = box.get(_moodKey) as String?;
        }
      }

      // Load tasks.
      final rawTasks = box.get(_tasksKey);
      if (rawTasks != null && rawTasks is List) {
        _tasks = rawTasks.map((e) => e.toString()).toList();
      }

      // Load or generate daily quote.
      final quoteDateStr = box.get(_quoteDateKey) as String?;
      if (quoteDateStr != null) {
        final quoteDate = DateTime.tryParse(quoteDateStr);
        if (quoteDate != null && _isSameDay(quoteDate, DateTime.now())) {
          _motivationalQuote = box.get(_quoteKey) as String?;
        }
      }
      if (_motivationalQuote == null) {
        _motivationalQuote = _pickRandomQuote();
        await box.put(_quoteKey, _motivationalQuote);
        await box.put(_quoteDateKey, DateTime.now().toIso8601String());
      }
    } catch (e, st) {
      dev.log('DailyProvider.loadDailyData failed', error: e, stackTrace: st);
      _error = 'Failed to load daily data.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Mood
  // ---------------------------------------------------------------------------

  /// Sets the user's mood for today. Persists to Hive.
  ///
  /// Typical values: 'happy', 'sad', 'neutral', 'excited', 'tired', 'anxious',
  /// or an emoji like '\u{1F60A}'.
  Future<void> setMood(String mood) async {
    _todaysMood = mood;
    notifyListeners();

    try {
      final box = await Hive.openBox(_boxName);
      await box.put(_moodKey, mood);
      await box.put(_moodDateKey, DateTime.now().toIso8601String());
    } catch (e, st) {
      dev.log('DailyProvider.setMood failed', error: e, stackTrace: st);
    }
  }

  /// Clears the mood selection for today.
  Future<void> clearMood() async {
    _todaysMood = null;
    notifyListeners();

    try {
      final box = await Hive.openBox(_boxName);
      await box.delete(_moodKey);
    } catch (e, st) {
      dev.log('DailyProvider.clearMood failed', error: e, stackTrace: st);
    }
  }

  // ---------------------------------------------------------------------------
  // Tasks
  // ---------------------------------------------------------------------------

  /// Adds a new task to today's list. Persists to Hive.
  Future<void> addTask(String task) async {
    final trimmed = task.trim();
    if (trimmed.isEmpty) return;

    _tasks.add(trimmed);
    notifyListeners();
    await _persistTasks();
  }

  /// Removes a task by index.
  Future<void> removeTask(int index) async {
    if (index < 0 || index >= _tasks.length) return;
    _tasks.removeAt(index);
    notifyListeners();
    await _persistTasks();
  }

  /// Toggles the completion state of a task at [index].
  ///
  /// Completed tasks are prefixed with '[x] ', incomplete ones with '[ ] '.
  Future<void> toggleTask(int index) async {
    if (index < 0 || index >= _tasks.length) return;

    final task = _tasks[index];
    if (task.startsWith('[x] ')) {
      _tasks[index] = task.replaceFirst('[x] ', '[ ] ');
    } else if (task.startsWith('[ ] ')) {
      _tasks[index] = task.replaceFirst('[ ] ', '[x] ');
    } else {
      // Task has no checkbox prefix yet; mark as complete.
      _tasks[index] = '[x] $task';
    }

    notifyListeners();
    await _persistTasks();
  }

  /// Clears all tasks for today.
  Future<void> clearTasks() async {
    _tasks.clear();
    notifyListeners();
    await _persistTasks();
  }

  // ---------------------------------------------------------------------------
  // Daily briefing
  // ---------------------------------------------------------------------------

  /// Generates a full daily briefing by refreshing the motivational quote
  /// and computing a greeting based on the time of day and mood.
  ///
  /// Returns a map with keys: 'greeting', 'quote', 'mood', 'taskSummary'.
  Future<Map<String, String>> generateDailyBriefing() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Refresh the quote.
      _motivationalQuote = _pickRandomQuote();
      final box = await Hive.openBox(_boxName);
      await box.put(_quoteKey, _motivationalQuote);
      await box.put(_quoteDateKey, DateTime.now().toIso8601String());

      // Build greeting based on time of day.
      final hour = DateTime.now().hour;
      String greeting;
      if (hour < 6) {
        greeting = 'تصبح على خير'; // Good night
      } else if (hour < 12) {
        greeting = 'صباح الخير'; // Good morning
      } else if (hour < 17) {
        greeting = 'مساء الخير'; // Good afternoon
      } else if (hour < 21) {
        greeting = 'مساء النور'; // Good evening
      } else {
        greeting = 'تصبح على خير'; // Good night
      }

      // Mood context.
      final moodLabel = _moodLabel(_todaysMood);

      // Task summary.
      final done = completedTaskCount;
      final total = totalTaskCount;
      final taskSummary = total == 0
          ? 'ما عندك حتى مهمة اليوم'
          : 'عندك $done من $total مهمات مكملين';

      final briefing = {
        'greeting': greeting,
        'quote': _motivationalQuote ?? '',
        'mood': moodLabel,
        'taskSummary': taskSummary,
      };

      return briefing;
    } catch (e, st) {
      dev.log('DailyProvider.generateDailyBriefing failed',
          error: e, stackTrace: st);
      _error = 'Failed to generate briefing.';
      return {
        'greeting': 'مرحبا',
        'quote': '',
        'mood': '',
        'taskSummary': '',
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Picks a random Darija quote (with translation) from the collection.
  String _pickRandomQuote() {
    final quote = _darijaQuotes[_random.nextInt(_darijaQuotes.length)];
    return '${quote['darija']}\n\n${quote['translation']}';
  }

  /// Returns a friendly Darija label for the mood value.
  String _moodLabel(String? mood) {
    switch (mood) {
      case 'happy':
        return 'فرحان';
      case 'sad':
        return 'حزين';
      case 'neutral':
        return 'عادي';
      case 'excited':
        return 'متحمس';
      case 'tired':
        return 'عييت';
      case 'anxious':
        return 'قلقان';
      default:
        return mood ?? '';
    }
  }

  /// Persists the current task list to Hive.
  Future<void> _persistTasks() async {
    try {
      final box = await Hive.openBox(_boxName);
      await box.put(_tasksKey, _tasks);
    } catch (e, st) {
      dev.log('DailyProvider._persistTasks failed', error: e, stackTrace: st);
    }
  }

  /// Returns true if [a] and [b] fall on the same calendar day.
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
