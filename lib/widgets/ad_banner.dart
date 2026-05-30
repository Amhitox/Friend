import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../services/ad_service.dart';
import '../services/subscription_service.dart';

/// A non-intrusive banner ad widget placed at the bottom of the screen.
///
/// The widget is responsible for:
/// - Only rendering for **free-tier** users (premium / VIP never see it).
/// - Wrapping the [BannerAd] loaded by [AdService].
/// - Showing a smooth slide + fade animation when the ad appears or hides.
/// - Displaying a branded placeholder while the ad is loading.
///
/// Usage:
/// ```dart
/// // Typically placed in the app builder or scaffold bottomNavigationBar area.
/// AdBanner(adService: adService)
/// ```
class AdBanner extends StatefulWidget {
  const AdBanner({super.key, required this.adService});

  /// The shared [AdService] that owns the underlying [BannerAd].
  final AdService adService;

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  // -----------------------------------------------------------------------
  // Lifecycle
  // -----------------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      reverseDuration: const Duration(milliseconds: 250),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));

    // Kick off the initial load attempt after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryLoadBanner());
  }

  @override
  void didUpdateWidget(covariant AdBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the adService instance changed (unlikely but defensive), reload.
    if (oldWidget.adService != widget.adService) {
      _disposeAd();
      _tryLoadBanner();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _disposeAd();
    super.dispose();
  }

  // -----------------------------------------------------------------------
  // Ad loading
  // -----------------------------------------------------------------------

  void _tryLoadBanner() {
    final subscription =
        Provider.of<SubscriptionService>(context, listen: false);

    // Premium / VIP users never see ads.
    if (!subscription.showAds) return;

    // If the AdService already has a loaded banner, grab it.
    final existing = widget.adService.getBannerAd();
    if (existing != null) {
      _attachAd(existing);
      return;
    }

    // Otherwise create a new one sized to the current screen width.
    final width = MediaQuery.of(context).size.width.truncate();
    final size = AdSize.getInlineAdaptiveBannerAdSize(width, 50);

    final ad = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad loaded) {
          if (!mounted) return;
          setState(() {
            _bannerAd = loaded as BannerAd;
            _isAdLoaded = true;
          });
          _animController.forward();
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
          if (mounted) {
            setState(() {
              _bannerAd = null;
              _isAdLoaded = false;
            });
          }
        },
      ),
    );

    ad.load();
    // Store reference so we can dispose later.
    _bannerAd = ad;
  }

  void _attachAd(BannerAd ad) {
    _bannerAd = ad;
    _isAdLoaded = true;
    if (mounted) _animController.forward();
  }

  void _disposeAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isAdLoaded = false;
  }

  // -----------------------------------------------------------------------
  // Build
  // -----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Double-check tier -- user may have upgraded since init.
    final subscription = Provider.of<SubscriptionService>(context);
    if (!subscription.showAds) {
      // Collapse the widget and animate out.
      if (_animController.isCompleted) _animController.reverse();
      return const SizedBox.shrink();
    }

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          width: double.infinity,
          color: Theme.of(context).scaffoldBackgroundColor,
          child: SafeArea(
            top: false,
            child: _isAdLoaded && _bannerAd != null
                ? SizedBox(
                    width: _bannerAd!.size.width.toDouble(),
                    height: _bannerAd!.size.height.toDouble(),
                    child: AdWidget(ad: _bannerAd!),
                  )
                : const _AdPlaceholder(),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _AdPlaceholder: branded placeholder shown while the ad is loading
// ---------------------------------------------------------------------------

class _AdPlaceholder extends StatelessWidget {
  const _AdPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.15),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Dostok',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withOpacity(0.5),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.8,
                ),
          ),
        ],
      ),
    );
  }
}
