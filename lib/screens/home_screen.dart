import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/daily_provider.dart';
import '../providers/chat_provider.dart';
import '../models/user_profile.dart';
import '../models/subscription.dart';
import '../services/subscription_service.dart';
import '../services/ad_service.dart';
import '../services/analytics_service.dart';
import '../services/feature_gate.dart';
import '../theme/app_colors.dart';
import '../widgets/subscription_status_card.dart';
import '../widgets/feature_lock.dart';
import '../widgets/premium_badge.dart';
import 'profile_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Home Screen (main shell with BottomNavigationBar)
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Track daily activity and load daily data on first launch.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().trackDailyActive();
      context.read<DailyProvider>().loadDailyData();
      AnalyticsService().logScreenView('home_screen');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const _HomeTab(),
          const _DailyTab(),
          const _ProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() => _currentIndex = i);
          final tabNames = ['home', 'daily', 'profile'];
          AnalyticsService().logScreenView('${tabNames[i]}_tab');
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Lqt diali',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_rounded),
            label: 'Nhar diali',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Home Tab (with Premium badge and Ad banner)
// ─────────────────────────────────────────────────────────────────────────────

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 18) return 'Sabah lkher';
    return 'Msa lkher';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProv = context.watch<UserProvider>();
    final chatProv = context.watch<ChatProvider>();
    final dailyProv = context.watch<DailyProvider>();
    final subService = context.watch<SubscriptionService>();

    final profile = userProv.currentUser;
    final name = userProv.displayName;
    final daysActive = profile?.daysActive ?? 0;
    final relationshipLevel = profile?.relationshipLevel ?? 0;

    // Build recent conversation previews from the last few messages.
    final recentMessages = chatProv.messages.reversed.take(4).toList();

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // ── Greeting header (avatar + name + notification bell) ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: profile?.avatarPath != null
                        ? ClipOval(
                            child: Image.asset(profile!.avatarPath!,
                                fit: BoxFit.cover, width: 44, height: 44),
                          )
                        : Icon(Icons.person, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_greeting()},',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (subService.isPremium) ...[
                              const SizedBox(width: 6),
                              PremiumBadge(
                                tier: subService.currentTier,
                                size: 16,
                                showLabel: false,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.notifications_none_rounded),
                      color: theme.colorScheme.primary,
                      onPressed: () {
                        final homeState =
                            context.findAncestorStateOfType<_HomeScreenState>();
                        homeState?.setState(() => homeState._currentIndex = 1);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Big "how can I help" headline ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text(
                'Kifash\nn3awnek lyoum?',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
            ),
          ),

          // ── Hero action grid: big "Talk to AI" + stacked Voice/Image ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: SizedBox(
                height: 188,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Big primary card with a "Start talking" pill button.
                    Expanded(
                      child: _HeroActionCard(
                        icon: Icons.auto_awesome_rounded,
                        title: 'Hder m3a\nDostok',
                        subtitle: 'Jarrb daba',
                        actionLabel: 'Bda hadra',
                        onTap: () => Navigator.pushNamed(context, '/chat'),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Stacked secondary cards.
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: FeatureLock(
                              feature: FeatureGate.voiceCalls,
                              tier: subService.currentTier,
                              teaser: true,
                              child: _MiniActionCard(
                                icon: Icons.graphic_eq_rounded,
                                label: 'Voice',
                                subtitle: 'Hder b-sotek',
                                color: const Color(0xFF9D4EDD),
                                onTap: () =>
                                    Navigator.pushNamed(context, '/call'),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Expanded(
                            child: _MiniActionCard(
                              icon: Icons.image_rounded,
                              label: 'Image',
                              subtitle: 'Sawb tsawer',
                              color: const Color(0xFFC77DFF),
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Sma7li, ghadi njik f update jay!')),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Topics row (label + See All) ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Text(
                    'Mawdu3at',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      final homeState =
                          context.findAncestorStateOfType<_HomeScreenState>();
                      homeState?.setState(() => homeState._currentIndex = 1);
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Kollshi'),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  for (var i = 0; i < _kHomeTopics.length; i++)
                    _TopicChip(
                      label: _kHomeTopics[i],
                      selected: i == 0,
                      onTap: () => Navigator.pushNamed(context, '/chat'),
                    ),
                ],
              ),
            ),
          ),

          // ── Suggestion cards (prompt starters with Discover) ──
          SliverToBoxAdapter(
            child: SizedBox(
              height: 150,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
                children: [
                  for (final s in _kHomeSuggestions)
                    _SuggestionCard(
                      question: s,
                      onTap: () => Navigator.pushNamed(context, '/chat'),
                    ),
                ],
              ),
            ),
          ),

          // ── Relationship progress ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.favorite_rounded,
                              color: theme.colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'M3a Dostok',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '$daysActive nhar',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: (relationshipLevel / 100).clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerLow,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Level: $relationshipLevel/100  ·  '
                        '${_relationshipTitle(relationshipLevel)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Motivational quote preview ──
          if (dailyProv.motivationalQuote != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Card(
                  elevation: 0,
                  color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.format_quote_rounded,
                            color: theme.colorScheme.primary, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            dailyProv.motivationalQuote!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontStyle: FontStyle.italic,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // ── Recent conversations ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Text(
                'Hadra ghi dazt',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (recentMessages.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerHighest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded,
                              size: 40, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text(
                            'Mazal makhderti m3a Dostok!',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Bda hadra daba',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final msg = recentMessages[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: msg.isFromUser
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.secondaryContainer,
                      child: Icon(
                        msg.isFromUser
                            ? Icons.person_rounded
                            : Icons.smart_toy_rounded,
                        color: msg.isFromUser
                            ? theme.colorScheme.primary
                            : theme.colorScheme.secondary,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      msg.content,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      msg.isFromUser ? 'Nta' : 'Dostok',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.pushNamed(context, '/chat'),
                  );
                },
                childCount: recentMessages.length,
              ),
            ),

          // ── Ad banner at bottom for free users ──
          if (subService.showAds)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: _AdBannerWidget(),
              ),
            ),

          // Bottom spacing for FAB
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  String _relationshipTitle(int level) {
    if (level >= 80) return 'Sahib 3omri';
    if (level >= 50) return 'Sahib qrib';
    if (level >= 20) return 'Sahib m3arfa';
    return 'Sahib jdida';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ad Banner Widget
// ─────────────────────────────────────────────────────────────────────────────

class _AdBannerWidget extends StatefulWidget {
  @override
  State<_AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<_AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) return const SizedBox.shrink();
    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Home content data (topics + suggestion starters)
// ─────────────────────────────────────────────────────────────────────────────

const List<String> _kHomeTopics = [
  'L7yat',
  'Khdma',
  'S77a',
  'T3lim',
  'Riyada',
  'Tbukh',
];

const List<String> _kHomeSuggestions = [
  'Shnu n9der ndir lyoum?',
  'Aatini fikra mzyana',
  '3awnni nfham had l7aja',
  'Gulli chi nokta',
];

// ─────────────────────────────────────────────────────────────────────────────
// Hero Action Card (big primary card with a "start" pill button)
// ─────────────────────────────────────────────────────────────────────────────

class _HeroActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback? onTap;

  const _HeroActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: AppColors.gradientPrimary,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.32),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const Spacer(),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionLabel,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded,
                        size: 16, color: AppColors.primary),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mini Action Card (compact tinted card)
// ─────────────────────────────────────────────────────────────────────────────

class _MiniActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _MiniActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: color.withOpacity(0.75),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Topic Chip
// ─────────────────────────────────────────────────────────────────────────────

class _TopicChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _TopicChip({
    required this.label,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: selected
                    ? AppColors.primary
                    : theme.colorScheme.outline.withOpacity(0.18),
              ),
            ),
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: selected
                    ? Colors.white
                    : theme.colorScheme.onSurface.withOpacity(0.75),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Suggestion Card (prompt starter with a Discover action)
// ─────────────────────────────────────────────────────────────────────────────

class _SuggestionCard extends StatelessWidget {
  final String question;
  final VoidCallback? onTap;

  const _SuggestionCard({required this.question, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: SizedBox(
        width: 180,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.06),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.auto_awesome_rounded,
                        size: 16, color: AppColors.primary),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Text(
                      question,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'Jarrb',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.arrow_forward_rounded,
                          size: 14, color: AppColors.primary),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Daily Tab (with Upgrade to Premium card for free users)
// ─────────────────────────────────────────────────────────────────────────────

class _DailyTab extends StatelessWidget {
  const _DailyTab();

  static const _moods = [
    {'emoji': '😊', 'label': 'happy'},
    {'emoji': '🔥', 'label': 'excited'},
    {'emoji': '😴', 'label': 'tired'},
    {'emoji': '😐', 'label': 'neutral'},
    {'emoji': '😤', 'label': 'anxious'},
    {'emoji': '😢', 'label': 'sad'},
  ];

  static const _moodDisplayLabels = {
    'happy': 'Mnichi',
    'excited': 'Motivated',
    'tired': 'T3ban',
    'neutral': '3adi',
    'anxious': 'M3ssab',
    'sad': 'Hzin',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daily = context.watch<DailyProvider>();
    final subService = context.watch<SubscriptionService>();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Header ──
          Text(
            'Nhar diali',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Kif dayr lyoum?',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          // ── Upgrade to Premium card for free users ──
          if (!subService.isPremium) ...[
            _buildUpgradeCard(context, theme),
            const SizedBox(height: 24),
          ],

          // ── Mood selector ──
          Text(
            'Shnu mood dialk?',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _moods.map((m) {
              final selected = daily.todaysMood == m['label'];
              return GestureDetector(
                onTap: () => daily.setMood(m['label']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: selected
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                    border: selected
                        ? Border.all(
                            color: theme.colorScheme.primary, width: 2)
                        : null,
                  ),
                  child: Column(
                    children: [
                      Text(m['emoji']!, style: const TextStyle(fontSize: 28)),
                      const SizedBox(height: 4),
                      Text(
                        _moodDisplayLabels[m['label']] ?? m['label']!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              selected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // ── Motivational quote ──
          if (daily.motivationalQuote != null)
            Card(
              elevation: 0,
              color: theme.colorScheme.primaryContainer.withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.format_quote_rounded,
                        color: theme.colorScheme.primary, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        daily.motivationalQuote!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),

          // ── Task list ──
          Row(
            children: [
              Text(
                'Mawahib lyoumia',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${daily.completedTaskCount}/${daily.totalTaskCount}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: daily.totalTaskCount > 0
                  ? daily.completedTaskCount / daily.totalTaskCount
                  : 0,
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainerLow,
            ),
          ),
          const SizedBox(height: 12),
          if (daily.tasks.isEmpty)
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.checklist_rounded,
                          size: 36, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        'Mazal maderti ta chi mission lyoum',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ...List.generate(daily.tasks.length, (i) {
              final task = daily.tasks[i];
              final isDone = task.startsWith('[x]');
              final displayText =
                  task.replaceFirst(RegExp(r'^\[[ x]\] '), '');
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 8),
                color: isDone
                    ? theme.colorScheme.surfaceContainerHighest
                    : theme.colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Icon(
                    isDone
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: isDone ? Colors.green : Colors.grey,
                  ),
                  title: Text(
                    displayText,
                    style: TextStyle(
                      decoration:
                          isDone ? TextDecoration.lineThrough : null,
                      color: isDone ? Colors.grey : null,
                    ),
                  ),
                  onTap: () => daily.toggleTask(i),
                ),
              );
            }),

          // ── Add task button ──
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: () => _showAddTaskDialog(context, daily),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Zid mission'),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildUpgradeCard(BuildContext context, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6C63FF).withOpacity(0.9),
            const Color(0xFF8B83FF).withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            AnalyticsService().logPaywallShown(
              trigger: 'daily_tab_card',
              placement: 'daily',
            );
            Navigator.of(context).pushNamed('/paywall');
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.rocket_launch_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Upgrade l-Premium!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Rassayil bla hd, mkimat, w bzf features akhra.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withOpacity(0.7),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context, DailyProvider daily) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Zid mission jdida'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Ktb mission dialk...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Lghi'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                daily.addTask(controller.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('Zid'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile Tab (with SubscriptionStatusCard)
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProv = context.watch<UserProvider>();
    final subService = context.watch<SubscriptionService>();

    final profile = userProv.currentUser;
    final name = userProv.displayName;
    final daysActive = profile?.daysActive ?? 0;
    final totalMessages = profile?.totalMessages ?? 0;

    // Map SubscriptionTier to DostokTier for the card widget.
    DostokTier cardTier;
    switch (subService.currentTier) {
      case SubscriptionTier.premium:
        cardTier = DostokTier.premium;
        break;
      case SubscriptionTier.vip:
        cardTier = DostokTier.vip;
        break;
      case SubscriptionTier.free:
      default:
        cardTier = DostokTier.free;
        break;
    }

    // Build usage data for the card.
    final maxMessages = subService.limits.maxAiResponsesPerDay;
    final maxCalls = subService.limits.maxCallMinutesPerDay;
    final usage = UsageData(
      messagesUsed: subService.currentUsage.aiResponsesReceived,
      messagesLimit: maxMessages == -1 ? -1 : maxMessages,
      callsUsed: subService.currentUsage.callMinutesUsed.toInt(),
      callsLimit: maxCalls == -1 ? -1 : maxCalls.toInt(),
      daysRemaining: subService.currentSubscription.daysRemaining,
    );

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Header ──
          Text(
            'Profil diali',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // ── Avatar + Name ──
          Center(
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: profile?.avatarPath != null
                          ? ClipOval(
                              child: Image.asset(profile!.avatarPath!,
                                  fit: BoxFit.cover,
                                  width: 104,
                                  height: 104),
                            )
                          : Icon(Icons.person_rounded,
                              size: 52, color: theme.colorScheme.primary),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.surface,
                            width: 3,
                          ),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Icon(Icons.edit_rounded,
                            size: 16, color: theme.colorScheme.onPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (subService.isPremium) ...[
                      const SizedBox(width: 8),
                      PremiumBadge(
                        tier: subService.currentTier,
                        size: 20,
                        showLabel: true,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Sahbi f Dostok mn $daysActive nhar',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ── Subscription Status Card ──
          SubscriptionStatusCard(
            tier: cardTier,
            usage: usage,
            onManage: () {
              Navigator.of(context).pushNamed('/paywall');
            },
            onUpgrade: () {
              AnalyticsService().logPaywallShown(
                trigger: 'profile_card',
                placement: 'profile',
              );
              Navigator.of(context).pushNamed('/paywall');
            },
          ),
          const SizedBox(height: 24),

          // ── Stats ──
          Row(
            children: [
              _MiniStat(
                value: '$daysActive',
                label: 'Nhar m3a b3diyyatna',
                icon: Icons.calendar_today_rounded,
              ),
              const SizedBox(width: 12),
              _MiniStat(
                value: '$totalMessages',
                label: 'Message',
                icon: Icons.message_rounded,
              ),
            ],
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mini Stat (reused from profile_screen)
// ─────────────────────────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _MiniStat({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
