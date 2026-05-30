import 'dart:math';

/// Collection of Moroccan Darija expressions, greetings, motivational quotes,
/// and cultural references that the AI companion uses to sound natural and
/// warm.
///
/// All entries are in Arabic script with transliteration comments. The
/// companion randomly picks from these lists to keep conversations fresh.
///
/// Usage:
/// ```dart
/// final greeting = DarijaExpressions.randomGreeting();
/// final quote = DarijaExpressions.randomMotivational();
/// ```
abstract final class DarijaExpressions {
  static final Random _random = Random();

  // ===========================================================================
  // Greetings
  // ===========================================================================

  /// Common greetings the AI uses to open a conversation.
  ///
  /// Ranges from very casual to warm and friendly.
  static const List<String> greetings = [
    'سلام! لاباس عليك؟', // Salam! Labas 3lik? = Hi! How are you?
    'أهلاً وسهلاً! كيداير/كيدايرا؟', // Ahlan! Kidayr/Kidayra? = Hey! How are you (m/f)?
    'صباح الخير يا صاحبي!', // Sabah l-kher ya sahbi! = Good morning my friend!
    'مساء الخير! شنو خبارك؟', // Msa l-kher! Shnu khabarek? = Good evening! What's new?
    'أهلاً أهلاً! كيف داير/دايرا؟', // Ahlan ahlan! Kif dayr/dayra? = Hey hey! How are you?
    'سلامو عليكم! لاباس عليكم؟', // Salamo 3likom! Labas 3likom? = Peace be upon you! How are you?
    'يا هلا! شنو واقع؟', // Ya hla! Shnu waqe3? = Hey! What's happening?
    'مرحبا صاحبي/صاحبتي!', // Mar7ba sahibi/sahbiti! = Welcome my friend (m/f)!
    'آش طاري؟', // Ash tari? = What's going on?
    'كيدايرا يا الغالي/الغالية؟', // Kidayra ya l-ghali/l-ghalya? = How are you, dear (m/f)?
  ];

  // ===========================================================================
  // Casual Conversation Fillers
  // ===========================================================================

  /// Phrases used between topics or as natural pauses in conversation.
  static const List<String> conversationFillers = [
    'واخا...', // Wakha... = Okay/Well...
    'إيه، و شنو بان ليك؟', // Iya, w shnu ban lik? = So, what do you think?
    'بالمناسبة...', // B lmantiqa... = By the way...
    'واقيلا...', // Waqila... = Maybe/Probably...
    'صافي، تافقنا', // Safi, tafaqna = Alright, agreed
    'هههه مزيان!', // Hhhh mzyan! = Haha nice!
    'بصح؟ ما تيقتش!', // Bse7? Ma tqst! = Really? I didn't believe it!
    'يا خويا/يا خوتي...', // Ya khoya/Ya khouti... = Bro/Folks...
    'بصراحة...', // B saraha... = Honestly...
    'الله يستر!', // Allah yoster! = May God protect! (expression of surprise)
  ];

  // ===========================================================================
  // Funny Expressions & Proverbs
  // ===========================================================================

  /// Classic Darija proverbs and funny sayings.
  ///
  /// Great for humor injection and cultural flavor.
  static const List<String> funnyExpressions = [
    // --- Proverbs ---
    'اللي ما عندو خوه، ما عندو مصدوق', // Li ma 3ando khawa, ma 3ando mssdoq
    // = Who has no sibling has no friend (value of close bonds)
    'الوقت كايجري، و حنا كانشوفو', // L-wqt kayjri, w 7na kanshufo
    // = Time runs and we just watch
    'ضربتين بزطام خاوي، تفكر صحابك', // Drbtin b zatam khawi, tfakkar sa7bek
    // = Hit twice with an empty wallet, you remember your friends
    'اللي بغا الزهر يصبر', // Li bgha z-zhar yssbar
    // = Who wants luck must be patient
    'كانشوفو لغيرة ديال الناس، و ما كانشوفوش ديالنا', // Kanshufo l-ghira dial n-nas, w ma kanshufoosh dialna
    // = We see others' jealousy but not our own
    'درت ديك الشي بحالي ما درت والو', // Dert dik shi 7ali ma dert walo
    // = I did that thing like I did nothing (effortless skill)
    'غادي نبكي ولا نضحك ما بقاتش فرق', // Ghadi nbki wla nd77k ma bqatsh frq
    // = I'm gonna cry or laugh, there's no difference anymore
    'كيحماقو عليا و ما كانعرفهمش', // Kay7maqo 3liya w ma kan3rfhomsh
    // = They love me and they don't even know me
    'سر ل幸福 ديالي؟ أكل زوين و نعاس مزيان', // Sirr l-bakht diali? Akil zwin w n3as mzyan
    // = My secret to happiness? Good food and good sleep
    'دابا نشوفو شكون يصبر أكثر', // Daba nshufo shkon yssbar akthar
    // = Now let's see who's more patient
  ];

  // ===========================================================================
  // Motivational Quotes (Darija)
  // ===========================================================================

  /// Motivational and inspirational quotes in Darija.
  ///
  /// Mix of original Moroccan wisdom and locally-adapted motivational thoughts.
  static const List<String> motivationalQuotes = [
    'كل نهار هو فرصة باش تبدا من جديد', // Kul nhar huhi fursa bash tbda mn jdid
    // = Every day is a chance to start fresh
    'ما كاين شي حاجة مستحيلة، غير خاصك تحاول', // Ma kayn shi 7aja musta7ila, ghir khassek t7awel
    // = Nothing is impossible, you just have to try
    'النجاح كايجي للي كايخدم بلا ما يتكلم', // Nnaja kayji li li kaykhdam bla ma ytkelem
    // = Success comes to those who work without complaining
    'نتا/نتي أقوى مما كاتظن', // Nta/Nti aqwa ma ma katssann
    // = You're stronger than you think
    'ما تخلي حتى شي نهار يدوز بلا ما تتعلم شي حاجة jdida', // Ma tkhalli 7ta shi nhar yduz bla ma tta3lam shi 7aja jdida
    // = Don't let a single day pass without learning something new
    'الطريق طويل، و لكن كل خطوة كاتهمنا', // T-triq twil, w lakin kul khatwa kathemna
    // = The road is long, but every step matters
    'غادي نوصل، غير صبر و خدم', // Ghadi nwsal, ghir ssbar w khdam
    // = I'll get there, just be patient and work
    'الحياة قصيرة، عيشها مزيان', // L-7aya 9sira, 3ishha mzyan
    // = Life is short, live it well
    'ما كاين للي كايبكي على شي حاجة فاتت، كاين للي كايبدا من جديد', // Ma kayn li li kaybki 3la shi 7aja fatit, kayn li kaybda mn jdid
    // = Don't cry over what's past, start anew
    'ثق فراسك، نتا/نتي كتعرف شنو كادير', // Thi9 f rassek, nta/nti kat3rf shnu kadir
    // = Believe in yourself, you know what you're doing
    'كل واحد فينا عندو قوة خفية', // Kul w7ad fna 3andu quwwa khfiya
    // = Each of us has a hidden strength
    'خليك ديما إيجابي، الحياة غادي تبتاسم ليك', // Khallik dma ijabhi, l-7aya ghadi tbttasem lik
    // = Stay positive, life will smile at you
  ];

  // ===========================================================================
  // Cultural References
  // ===========================================================================

  /// References to Moroccan culture -- food, places, music, traditions --
  /// that the AI drops into conversation to feel authentically Moroccan.
  static const List<String> culturalReferences = [
    // --- Food ---
    'واش كتحب الطاجين؟ أنا كنموت عليه!', // Wash kat7ib t-tajine? Ana kanmut 3lih!
    // = Do you love tajine? I'm crazy about it!
    'الحريرة ديال رمضان، مافيها مثيل', // L-7arira dial Rmdan, mafihha mithil
    // = Ramadan harira soup is unbeatable
    'المسمن مع العسل و الزبدة، توب!', // L-msmen m3a l-3sl w z-zubda, tub!
    // = Msmen (flatbread) with honey and butter, top!
    'شاي بالنعناع هو ل solution ديال كل مشكيل', // Shay b n-na3na3 huwa l-solution dial kul mshkil
    // = Mint tea is the solution to every problem
    'كنتسناو الدخان ديال البراد بحال كنتسناو شي خبر زوين', // Kantssnnaw d-dkhan dial b-barad b7al kantssnnaw shi khabar zwin
    // = We wait for the teapot steam like waiting for good news

    // --- Places ---
    'كازا ديالنا، مدينة ما كاتنمشش', // Casa dialna, madina ma katnmshsh
    // = Our Casablanca, a city that never sleeps
    'شفشاون لزرقة ديالها كاتخليك تحس براسك فتصويرة', // Shfshawn z-zarqa dialha katkhallik t7iss brassek f taswira
    // = Chefchaouen's blue makes you feel like you're in a painting
    'مراكش، سوقها و جامع الفنا!', // Marrakesh, souqha w Jama3 l-fna!
    // = Marrakesh, its market and Jemaa el-Fnaa!
    'طريق الصويرة كتجنن بالمناظر', // Triq s-Sawira ktjnn b l-manazir
    // = The road to Essaouira is stunning

    // --- Music & Art ---
    'واش سمعتي شي كناوي اليوم؟ يداوي الروح', // Wash sma3ti shi Gnawi l-yum? Ydawi r-ru7
    // = Did you hear any Gnawa music today? It heals the soul
    'العيطة ديالنا، فن ما كايموتش', // L-3ayta dialna, fann ma kaymutsh
    // = Aita (traditional singing), an art that doesn't die
    'Chaabi dial l-maharba!', // الشعبي ديال المهرابا
    // = Chaabi music of the festivities!

    // --- Traditions ---
    'القهوة ديال الصباح معا لمخاخ، لحظة مقدسة', // L-qahwa dial s-sba7 m3a l-mkhakh, la7da muqaddasa
    // = Morning coffee with the brains, a sacred moment
    'سهرة معا لعائلة و أتاي، ما كاين أحسن', // Shra m3a l-3a2ila w atay, ma kayn a7san
    // = Evening with family and tea, nothing better
    'سوق الأحد، adventure ديال كل أسبوع', // Souq l-7did, adventure dial kul usbu3
    // = Sunday market, an adventure every week
  ];

  // ===========================================================================
  // Encouragement & Empathy
  // ===========================================================================

  /// Phrases for when the user seems down or needs support.
  static const List<String> encouragement = [
    'ما تقلق، أنا معاك ديما', // Ma tqlq, ana m3ak dma
    // = Don't worry, I'm always with you
    'هادي غير مرحلة، غادي تدوز', // Hadi ghir mar7ala, ghadi tduz
    // = This is just a phase, it'll pass
    'نتا/نتي قوي/قوية، غادي تتخطى هادشي', // Nta/Nti qawi/qawiya, ghadi ttkhatta hadshi
    // = You're strong, you'll get through this
    'ماشي مشكيل، كلنا كانغلطو', // Mashi mshkil, kulna kanghalitu
    // = No problem, we all make mistakes
    'خود وقتك، ما كاين لاش تستعجل', // Khud wqtek, ma kayn lash tst3jil
    // = Take your time, no need to rush
    'أنا هنا معاك، هضر معايا', // Ana hna m3ak, hdir m3aya
    // = I'm here with me, talk to me
    'غادي ندوزو هادشي بجوج', // Ghadi ndouzzo hadshi b jouj
    // = We'll get through this together
    'سير قدام، أنا موراك ديما', // Sir qddam, ana murrak dma
    // = Go forward, I'm always behind you
  ];

  // ===========================================================================
  // Farewells
  // ===========================================================================

  /// Goodbye phrases with cultural warmth.
  static const List<String> farewells = [
    'بسلامة! تهلا فراسك', // Bssalama! Thla f rassek
    // = Goodbye! Take care of yourself
    'إلى اللقاء يا صاحبي/صاحبتي!', // Ila l-liqa ya sahibi/sahbiti!
    // = See you later, my friend!
    'تصبح على خير! نشوفو غدا إن شاء الله', // Tsb7 3la kher! Nshufo ghadan insha'Allah
    // = Good night! See you tomorrow God willing
    'باي باي! ما تنسانيش', // Bye bye! Ma tnsanish
    // = Bye bye! Don't forget me
    'سلام! و رجع ليا بأخبار زوينة', // Salam! W rj3 liya b akhbar zwin
    // = Peace! Come back with good news
    'تصبح/تصبحي على خير، نهارك يدوز مزيان', // Tsb7/tsb7i 3la kher, nharak yduz mzyan
    // = Good night (m/f), have a great day
  ];

  // ===========================================================================
  // Response Modifiers
  // ===========================================================================

  /// Phrases used to soften or enhance responses.
  static const List<String> responseModifiers = [
    'بصح؟', // Bse7? = Really?
    'واش من نيتك؟', // Wash men nittek? = Are you serious?
    'يا سلام!', // Ya salam! = Wow!
    'ما شاء الله!', // Ma sha'Allah! = God has willed it! (impressed)
    'الحمد لله!', // Alhamdulillah! = Thank God!
    'إن شاء الله', // Insha'Allah = God willing
    'بصحة!', // Bsi7a! = Cheers! / Good for you!
    'تبارك الله', // TabarakAllah = Blessing (admiration)
    'ههههه', // Hhhhh = Hahaha (Moroccan style)
    'اوف!', // Ouf! = Phew! / Wow!
  ];

  // ===========================================================================
  // Random pickers
  // ===========================================================================

  /// Returns a random greeting from [greetings].
  static String randomGreeting() => _pick(greetings);

  /// Returns a random conversation filler from [conversationFillers].
  static String randomFiller() => _pick(conversationFillers);

  /// Returns a random funny expression or proverb from [funnyExpressions].
  static String randomFunnyExpression() => _pick(funnyExpressions);

  /// Returns a random motivational quote from [motivationalQuotes].
  static String randomMotivational() => _pick(motivationalQuotes);

  /// Returns a random cultural reference from [culturalReferences].
  static String randomCulturalReference() => _pick(culturalReferences);

  /// Returns a random encouragement phrase from [encouragement].
  static String randomEncouragement() => _pick(encouragement);

  /// Returns a random farewell from [farewells].
  static String randomFarewell() => _pick(farewells);

  /// Returns a random response modifier from [responseModifiers].
  static String randomResponseModifier() => _pick(responseModifiers);

  // ===========================================================================
  // Internal helpers
  // ===========================================================================

  /// Picks a random element from [list].
  static String _pick(List<String> list) => list[_random.nextInt(list.length)];
}
