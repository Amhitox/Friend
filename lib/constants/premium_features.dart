import 'package:flutter/material.dart';

/// Premium features constants and comparison data for Dostok.
///
/// Contains:
/// - Feature descriptions in Darija and English
/// - Icons and illustrations
/// - Paywall comparison data
/// - Marketing copy
class PremiumFeatures {
  PremiumFeatures._();

  // ─── Feature Definitions ──────────────────────────────────────────────

  static const List<PremiumFeature> allFeatures = [
    PremiumFeature(
      id: 'unlimited_messages',
      nameEn: 'Unlimited Messages',
      nameDarija: 'Messages bla 7d',
      descriptionEn: 'Chat as much as you want with your AI companion',
      descriptionDarija: 'Hdr m3a AI b ay tri9a bghiti - bla 7d',
      icon: Icons.chat_bubble_rounded,
      marketingCopyEn: 'Never run out of conversations. Practice Darija anytime, day or night.',
      marketingCopyDarija: 'Ma tswa3ch l hdra. T3allam Darija f ay wa9t.',
      isFree: false,
      category: FeatureCategory.core,
    ),
    PremiumFeature(
      id: 'voice_calls',
      nameEn: 'Voice Calls',
      nameDarija: 'Appels b ssot',
      descriptionEn: 'Practice speaking with real-time voice conversations',
      descriptionDarija: 'Tdarra3 klmk m3a AI b ssot dyalek - 7na nghadro nsm3ok!',
      icon: Icons.call_rounded,
      marketingCopyEn: 'Master pronunciation with real-time voice calls. Your AI understands Darija accents.',
      marketingCopyDarija: 'T3allam kifach ttklm b Darija m3a AI li fahmek.',
      isFree: false,
      category: FeatureCategory.core,
    ),
    PremiumFeature(
      id: 'smart_corrections',
      nameEn: 'Smart Corrections',
      nameDarija: 'T7sin dyalek',
      descriptionEn: 'Get instant grammar and vocabulary corrections',
      descriptionDarija: 'AI ghadi y7sn l grammer dyalek f l wa9t',
      icon: Icons.auto_fix_high_rounded,
      marketingCopyEn: 'Learn from your mistakes instantly. No more repeating errors.',
      marketingCopyDarija: 'T3allm mn l aghlat dyalek f l wa9t. Ma3adch t3awdhom.',
      isFree: true,
      category: FeatureCategory.learning,
    ),
    PremiumFeature(
      id: 'cultural_tips',
      nameEn: 'Cultural Tips',
      nameDarija: 'M3lumat th9afiya',
      descriptionEn: 'Learn Moroccan culture, traditions, and expressions',
      descriptionDarija: 'T3allm 3la l th9afa l maghribiya w l ta3abir',
      icon: Icons.mosque_rounded,
      marketingCopyEn: 'Understand the culture behind the language. Real Moroccan expressions.',
      marketingCopyDarija: 'Fham l th9afa wara l lgha. Ta3abir maghribiya 7a9i9iya.',
      isFree: false,
      category: FeatureCategory.cultural,
    ),
    PremiumFeature(
      id: 'daily_lessons',
      nameEn: 'Daily Lessons',
      nameDarija: 'Dروس يومية',
      descriptionEn: 'Structured daily lessons tailored to your level',
      descriptionDarija: 'Dروس nti9iya kul yum mn 7sab l mou3a dyalek',
      icon: Icons.school_rounded,
      marketingCopyEn: 'Follow a structured path. Lessons adapt to your progress.',
      marketingCopyDarija: 'Tbi3 tri9 m9adam. Dروس t9ad m3ak.',
      isFree: true,
      category: FeatureCategory.learning,
    ),
    PremiumFeature(
      id: 'offline_mode',
      nameEn: 'Offline Mode',
      nameDarija: 'Khdma bla internet',
      descriptionEn: 'Download lessons and practice without internet',
      descriptionDarija: '7ml dروس w trann m3aha bla ma tkon m3a internet',
      icon: Icons.offline_bolt_rounded,
      marketingCopyEn: 'Learn anywhere, even without internet. Perfect for travel.',
      marketingCopyDarija: 'T3allm f ay blasa, 7ta bla internet. Momtaz l sfr.',
      isFree: false,
      category: FeatureCategory.premium,
    ),
    PremiumFeature(
      id: 'progress_tracking',
      nameEn: 'Progress Tracking',
      nameDarija: 'Tbi3 l mou3a',
      descriptionEn: 'Detailed analytics of your learning journey',
      descriptionDarija: 'M3lumat t9ila 3la tri9at t3allm dyalek',
      icon: Icons.insights_rounded,
      marketingCopyEn: 'Track every milestone. See how far you\'ve come.',
      marketingCopyDarija: 'Tbi3 kul mara wach wsalti. Chof kifach t9addamti.',
      isFree: false,
      category: FeatureCategory.learning,
    ),
    PremiumFeature(
      id: 'conversation_scenarios',
      nameEn: 'Real Scenarios',
      nameDarija: 'Mwarid 7a9i9iya',
      descriptionEn: 'Practice real-life situations: shopping, taxi, restaurant...',
      descriptionDarija: 'Tdarra3 f mwarid 7a9i9iya: l marché, taxi, restaurant...',
      icon: Icons.theater_comedy_rounded,
      marketingCopyEn: 'Prepare for real conversations. Shopping, directions, food - we cover it all.',
      marketingCopyDarija: 'Hddar nafsek l hdra 7a9i9iya. L marché, taxi, restaurant - koulchi.',
      isFree: false,
      category: FeatureCategory.cultural,
    ),
    PremiumFeature(
      id: 'multiple_dialects',
      nameEn: 'Multiple Dialects',
      nameDarija: 'Lahjat mukhtalfa',
      descriptionEn: 'Learn Casablanca, Fes, Marrakech and other regional dialects',
      descriptionDarija: 'T3allam lahja dyalek: dar l baida, fas, mrraksh...',
      icon: Icons.language_rounded,
      marketingCopyEn: 'Explore regional differences. Casablanca to Marrakech and beyond.',
      marketingCopyDarija: 'Chof l fou9oulat. Mn dar l baida l mrraksh w zid.',
      isFree: false,
      category: FeatureCategory.cultural,
    ),
    PremiumFeature(
      id: 'ai_personality',
      nameEn: 'AI Personality',
      nameDarija: 'Chakhsiya dyalek',
      descriptionEn: 'Choose your AI companion\'s personality and teaching style',
      descriptionDarija: 'Khtar chakhsiya dyalek w kifach y3lmk',
      icon: Icons.psychology_rounded,
      marketingCopyEn: 'Your AI adapts to you. Strict teacher or friendly conversation partner?',
      marketingCopyDarija: 'AI dyalek t9ad m3ak. M3allm s3ib wla sa7bek?',
      isFree: false,
      category: FeatureCategory.premium,
    ),
    PremiumFeature(
      id: 'exam_prep',
      nameEn: 'Exam Preparation',
      nameDarija: 'Tjhid l imti7an',
      descriptionEn: 'Prepare for Moroccan Arabic proficiency tests',
      descriptionDarija: 'Tjhid nafsek l imti7anat dyalek',
      icon: Icons.quiz_rounded,
      marketingCopyEn: 'Acing your Darija exams? We\'ve got the practice you need.',
      marketingCopyDarija: 'Bghiti tnj7 f imti7an dyalek? 3ndna l mou3a li khassek.',
      isFree: false,
      category: FeatureCategory.learning,
    ),
    PremiumFeature(
      id: 'priority_support',
      nameEn: 'Priority Support',
      nameDarija: 'Mous3ada sari3a',
      descriptionEn: 'Get help within 24 hours from our team',
      descriptionDarija: 'L9a mous3ada f 24 sa3a mn ekip dyalek',
      icon: Icons.support_agent_rounded,
      marketingCopyEn: 'Stuck? Our team responds within 24 hours. We\'re here for you.',
      marketingCopyDarija: '3ndek mshkil? L ekip dyalek yjewbk f 24 sa3a. 7na hna.',
      isFree: false,
      category: FeatureCategory.premium,
    ),
  ];

  // ─── Free vs Premium Comparison ───────────────────────────────────────

  static const Map<String, FeatureComparison> comparisonData = {
    'messages': FeatureComparison(
      feature: 'Daily Messages',
      freeValue: '50/day',
      premiumValue: 'Unlimited',
      icon: Icons.chat,
    ),
    'voice_calls': FeatureComparison(
      feature: 'Voice Calls',
      freeValue: '3/week',
      premiumValue: 'Unlimited',
      icon: Icons.call,
    ),
    'offline': FeatureComparison(
      feature: 'Offline Access',
      freeValue: 'No',
      premiumValue: 'Yes',
      icon: Icons.offline_bolt,
    ),
    'scenarios': FeatureComparison(
      feature: 'Real Scenarios',
      freeValue: '3 basic',
      premiumValue: '50+ scenarios',
      icon: Icons.theater_comedy,
    ),
    'dialects': FeatureComparison(
      feature: 'Dialects',
      freeValue: 'Standard only',
      premiumValue: 'All regions',
      icon: Icons.language,
    ),
    'progress': FeatureComparison(
      feature: 'Progress Tracking',
      freeValue: 'Basic',
      premiumValue: 'Detailed',
      icon: Icons.insights,
    ),
    'corrections': FeatureComparison(
      feature: 'Smart Corrections',
      freeValue: 'Limited',
      premiumValue: 'Always on',
      icon: Icons.auto_fix_high,
    ),
    'support': FeatureComparison(
      feature: 'Support',
      freeValue: 'Community',
      premiumValue: '24h priority',
      icon: Icons.support_agent,
    ),
  };

  // ─── Marketing Copy ───────────────────────────────────────────────────

  static const String headlineEn = 'Unlock the full Dostok experience';
  static const String headlineDarija = '7ll tajriba kamla dyalek m3a Dostok';

  static const String subheadlineEn =
      'Unlimited messages, voice calls, and real-life scenarios to master Moroccan Darija';
  static const String subheadlineDarija =
      'Messages bla 7d, appels b ssot, w mwarid 7a9i9iya bach t3llam Darija l maghribiya';

  static const String ctaEn = 'Start Free Trial';
  static const String ctaDarija = 'Bda l mjawla bla floos';

  static const String socialProofEn = 'Join 10,000+ learners mastering Darija';
  static const String socialProofDarija = 'Wsaf m3a 10,000+ li t3llamo Darija';

  // ─── Paywall Copy ─────────────────────────────────────────────────────

  static const List<String> paywallBulletPointsEn = [
    'Unlimited AI conversations',
    'Voice calls with accent feedback',
    '50+ real-life scenarios',
    'All Moroccan dialects',
    'Offline lessons',
    'Priority support',
  ];

  static const List<String> paywallBulletPointsDarija = [
    'Hdra m3a AI bla 7d',
    'Appels b ssot w t7sin l accent',
    '50+ mwarid 7a9i9iya',
    'Kul l lahjat l maghribiya',
    'Dروس bla internet',
    'Mous3ada sari3a',
  ];

  // ─── Trial Copy ───────────────────────────────────────────────────────

  static const String trialHeadlineEn = 'Try Premium free for 7 days';
  static const String trialHeadlineDarija = 'Jrb Premium bla floos l 7 jours';

  static const String trialSubheadlineEn = 'No commitment. Cancel anytime during trial.';
  static const String trialSubheadlineDarija = 'Bl iltizam. Lghi f ay wa9t f l mjawla.';

  // ─── Feature Categories ───────────────────────────────────────────────

  static List<PremiumFeature> getFeaturesByCategory(FeatureCategory category) {
    return allFeatures.where((f) => f.category == category).toList();
  }

  static List<PremiumFeature> get freeFeatures =>
      allFeatures.where((f) => f.isFree).toList();

  static List<PremiumFeature> get premiumFeatures =>
      allFeatures.where((f) => !f.isFree).toList();
}

// ─── Data Classes ─────────────────────────────────────────────────────

/// Represents a single premium feature.
class PremiumFeature {
  final String id;
  final String nameEn;
  final String nameDarija;
  final String descriptionEn;
  final String descriptionDarija;
  final IconData icon;
  final String marketingCopyEn;
  final String marketingCopyDarija;
  final bool isFree;
  final FeatureCategory category;

  const PremiumFeature({
    required this.id,
    required this.nameEn,
    required this.nameDarija,
    required this.descriptionEn,
    required this.descriptionDarija,
    required this.icon,
    required this.marketingCopyEn,
    required this.marketingCopyDarija,
    required this.isFree,
    required this.category,
  });
}

/// Comparison between free and premium feature values.
class FeatureComparison {
  final String feature;
  final String freeValue;
  final String premiumValue;
  final IconData icon;

  const FeatureComparison({
    required this.feature,
    required this.freeValue,
    required this.premiumValue,
    required this.icon,
  });
}

/// Categories for organizing features.
enum FeatureCategory {
  core,
  learning,
  cultural,
  premium,
}
