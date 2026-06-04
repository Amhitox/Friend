import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/firebase_config.dart';
import 'subscription_service.dart';

/// Manages non-intrusive ad placements for Dostok's free tier users.
///
/// The ad philosophy:
/// - Ads fund the free experience, not punish the user.
/// - Never during sacred moments (calls, check-ins, typing).
/// - Frequency capping prevents ad fatigue.
/// - Rewarded ads give the user agency -- watch to earn more messages.
/// - Premium/VIP users never see ads.
///
/// Usage:
/// ```dart
/// final adService = AdService(subscriptionService);
/// await adService.initialize();
///
/// // Show banner on home screen
/// final banner = adService.createBannerAd();
///
/// // After every 15th message
/// if (adService.shouldShowInterstitial(messageCount)) {
///   await adService.showInterstitialAd();
/// }
///
/// // Rewarded ad for bonus messages
/// final earned = await adService.showRewardedAd();
/// if (earned) grantExtraMessages(5);
/// ```
class AdService {
  // ---------------------------------------------------------------------------
  // Constants
  // ---------------------------------------------------------------------------

  static const String _tag = 'AdService';

  /// How many messages between interstitial ad opportunities.
  ///
  /// 15 is enough to not feel spammy, but frequent enough to matter.
  /// An interstitial after every 15th AI response.
  static const int interstitialFrequency = 15;

  /// Minimum seconds between interstitial ads (frequency capping).
  ///
  /// Even if the user messages fast, we won't show back-to-back ads.
  /// 120 seconds = 2 minutes minimum between interstitials.
  static const int minInterstitialGapSeconds = 120;

  /// Number of bonus messages earned by watching a rewarded ad.
  static const int rewardedBonusMessages = 5;

  /// Maximum rewarded ads per day to prevent abuse.
  static const int maxRewardedAdsPerDay = 4;

  /// Test ad unit IDs for development.
  ///
  /// IMPORTANT: Replace with production IDs before release.
  /// These are Google's official test IDs that always serve test ads.
  static const String _testBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  // ---------------------------------------------------------------------------
  // Production ad unit IDs
  // ---------------------------------------------------------------------------
  // Uncomment and set these before release.
  //
  // static const String _prodBannerAdUnitId = 'ca-app-pub-XXXXX/XXXXX';
  // static const String _prodInterstitialAdUnitId = 'ca-app-pub-XXXXX/XXXXX';
  // static const String _prodRewardedAdUnitId = 'ca-app-pub-XXXXX/XXXXX';

  // ---------------------------------------------------------------------------
  // Ad unit ID getters (swap to production when ready)
  // ---------------------------------------------------------------------------

  /// Banner ad unit ID. Uses test IDs in debug mode, production in release.
  static String get bannerAdUnitId {
    if (kDebugMode) return _testBannerAdUnitId;
    // return _prodBannerAdUnitId; // Uncomment for production
    return _testBannerAdUnitId;
  }

  /// Interstitial ad unit ID.
  static String get interstitialAdUnitId {
    if (kDebugMode) return _testInterstitialAdUnitId;
    // return _prodInterstitialAdUnitId; // Uncomment for production
    return _testInterstitialAdUnitId;
  }

  /// Rewarded ad unit ID.
  static String get rewardedAdUnitId {
    if (kDebugMode) return _testRewardedAdUnitId;
    // return _prodRewardedAdUnitId; // Uncomment for production
    return _testRewardedAdUnitId;
  }

  // ---------------------------------------------------------------------------
  // Dependencies
  // ---------------------------------------------------------------------------

  final SubscriptionService _subscriptionService;

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  /// Whether the Google Mobile Ads SDK has been initialized.
  bool _isInitialized = false;

  /// The currently loaded banner ad, if any.
  BannerAd? _bannerAd;

  /// Whether a banner ad is currently loaded and ready to display.
  bool _isBannerLoaded = false;

  /// The currently loaded interstitial ad, if any.
  InterstitialAd? _interstitialAd;

  /// Whether an interstitial ad is currently loaded and ready.
  bool _isInterstitialLoaded = false;

  /// The currently loaded rewarded ad, if any.
  RewardedAd? _rewardedAd;

  /// Whether a rewarded ad is currently loaded and ready.
  bool _isRewardedLoaded = false;

  /// Timestamp of the last interstitial ad shown, for frequency capping.
  DateTime? _lastInterstitialTime;

  /// Number of rewarded ads shown today.
  int _rewardedAdsShownToday = 0;

  /// Date for tracking daily rewarded ad count.
  DateTime _rewardedAdsDate = DateTime(2000);

  // ---------------------------------------------------------------------------
  // Constructor
  // ---------------------------------------------------------------------------

  /// Creates an [AdService] bound to the given [SubscriptionService].
  ///
  /// The subscription service is used to check whether the user is on a
  /// paid tier (in which case no ads are shown).
  AdService(this._subscriptionService);

  // ---------------------------------------------------------------------------
  // Public getters
  // ---------------------------------------------------------------------------

  /// Whether the ad SDK has been initialized.
  bool get isInitialized => _isInitialized;

  /// Whether a banner ad is loaded and ready to display.
  bool get isBannerLoaded => _isBannerLoaded;

  /// The loaded banner ad, or null if not available.
  BannerAd? get bannerAd => _bannerAd;

  /// Whether ads should be shown to the current user.
  ///
  /// Returns false for premium and VIP users, true for free tier.
  bool get shouldShowAds => _subscriptionService.showAds;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Initializes the Google Mobile Ads SDK and pre-loads ads.
  ///
  /// Must be called before any ad methods. Safe to call multiple times --
  /// subsequent calls are no-ops.
  ///
  /// Returns `true` if initialization succeeds.
  Future<bool> initialize() async {
    if (_isInitialized) {
      dev.log('Already initialized', name: _tag);
      return true;
    }

    // Skip ads in demo mode or on unsupported platforms.
    if (FirebaseConfig.isDemoMode) {
      dev.log('Demo mode — skipping ads', name: _tag);
      return false;
    }

    if (!Platform.isAndroid && !Platform.isIOS) {
      dev.log('Ads not supported on this platform — skipping', name: _tag);
      return false;
    }

    try {
      dev.log('Initializing Google Mobile Ads SDK...', name: _tag);

      final initStatus = await MobileAds.instance.initialize();
      dev.log(
        'Mobile Ads SDK initialized: '
        '${initStatus.adapterStatuses.keys.join(', ')}',
        name: _tag,
      );

      _isInitialized = true;

      // Pre-load ads for a smooth experience.
      _loadBannerAd();
      _loadInterstitialAd();
      _loadRewardedAd();

      // Reset daily rewarded count if needed.
      _checkRewardedDate();

      return true;
    } catch (e, st) {
      dev.log('Ad initialization failed', name: _tag, error: e, stackTrace: st);
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Banner ads
  // ---------------------------------------------------------------------------

  /// Creates and returns a [BannerAd] for the home screen bottom.
  ///
  /// The banner is sized for the current screen width and uses an adaptive
  /// format for best results. Returns null if the user is on a paid tier
  /// or if the ad fails to load.
  ///
  /// The caller should use [bannerAd] after checking [isBannerLoaded].
  void _loadBannerAd() {
    if (!shouldShowAds) {
      dev.log('Skipping banner load -- user is premium', name: _tag);
      return;
    }

    _bannerAd?.dispose();
    _bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          dev.log('Banner ad loaded', name: _tag);
          _isBannerLoaded = true;
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          dev.log(
            'Banner ad failed to load: ${error.message}',
            name: _tag,
            error: error,
          );
          ad.dispose();
          _bannerAd = null;
          _isBannerLoaded = false;
        },
        onAdOpened: (Ad ad) {
          dev.log('Banner ad opened', name: _tag);
        },
        onAdClosed: (Ad ad) {
          dev.log('Banner ad closed', name: _tag);
        },
      ),
    );

    _bannerAd!.load();
  }

  /// Returns the loaded banner ad for display.
  ///
  /// Returns null if no banner is loaded or if the user is on a paid tier.
  BannerAd? getBannerAd() {
    if (!shouldShowAds) return null;
    if (!_isBannerLoaded || _bannerAd == null) return null;
    return _bannerAd;
  }

  // ---------------------------------------------------------------------------
  // Interstitial ads
  // ---------------------------------------------------------------------------

  /// Pre-loads an interstitial ad for later display.
  void _loadInterstitialAd() {
    if (!shouldShowAds) return;

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          dev.log('Interstitial ad loaded', name: _tag);
          _interstitialAd = ad;
          _isInterstitialLoaded = true;
        },
        onAdFailedToLoad: (LoadAdError error) {
          dev.log(
            'Interstitial ad failed to load: ${error.message}',
            name: _tag,
            error: error,
          );
          _interstitialAd = null;
          _isInterstitialLoaded = false;
        },
      ),
    );
  }

  /// Determines whether an interstitial ad should be shown.
  ///
  /// Conditions:
  /// - User must be on free tier ([shouldShowAds] is true)
  /// - An interstitial ad must be loaded
  /// - At least [interstitialFrequency] messages since last interstitial
  ///   (or since session start)
  /// - At least [minInterstitialGapSeconds] seconds since last interstitial
  /// - The user must not be in the middle of typing (caller's responsibility)
  ///
  /// [messageCount] is the total AI response count for the current session
  /// or day.
  bool shouldShowInterstitial(int messageCount) {
    if (!shouldShowAds) return false;
    if (!_isInterstitialLoaded) return false;

    // Check message frequency.
    if (messageCount % interstitialFrequency != 0) return false;

    // Check time gap (frequency capping).
    if (_lastInterstitialTime != null) {
      final elapsed = DateTime.now().difference(_lastInterstitialTime!);
      if (elapsed.inSeconds < minInterstitialGapSeconds) {
        dev.log(
          'Interstitial suppressed (too soon: '
          '${elapsed.inSeconds}s < ${minInterstitialGapSeconds}s)',
          name: _tag,
        );
        return false;
      }
    }

    return true;
  }

  /// Shows the loaded interstitial ad.
  ///
  /// Returns `true` if the ad was shown and completed, `false` if no ad
  /// was available or the user dismissed it early.
  ///
  /// After the ad closes, a new interstitial is pre-loaded.
  Future<bool> showInterstitialAd() async {
    if (!_isInterstitialLoaded || _interstitialAd == null) {
      dev.log('No interstitial ad available', name: _tag);
      return false;
    }

    final completer = Completer<bool>();

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) {
        dev.log('Interstitial ad shown', name: _tag);
        _lastInterstitialTime = DateTime.now();
      },
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        dev.log('Interstitial ad dismissed', name: _tag);
        ad.dispose();
        _interstitialAd = null;
        _isInterstitialLoaded = false;
        _loadInterstitialAd(); // Pre-load the next one.
        completer.complete(true);
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        dev.log(
          'Interstitial ad failed to show: ${error.message}',
          name: _tag,
          error: error,
        );
        ad.dispose();
        _interstitialAd = null;
        _isInterstitialLoaded = false;
        _loadInterstitialAd();
        completer.complete(false);
      },
    );

    await _interstitialAd!.show();
    return completer.future;
  }

  // ---------------------------------------------------------------------------
  // Rewarded ads
  // ---------------------------------------------------------------------------

  /// Pre-loads a rewarded ad for later display.
  void _loadRewardedAd() {
    if (!shouldShowAds) return;

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          dev.log('Rewarded ad loaded', name: _tag);
          _rewardedAd = ad;
          _isRewardedLoaded = true;
        },
        onAdFailedToLoad: (LoadAdError error) {
          dev.log(
            'Rewarded ad failed to load: ${error.message}',
            name: _tag,
            error: error,
          );
          _rewardedAd = null;
          _isRewardedLoaded = false;
        },
      ),
    );
  }

  /// Whether a rewarded ad is available to show.
  ///
  /// Returns false if:
  /// - User is on a paid tier
  /// - No rewarded ad is loaded
  /// - Daily rewarded ad cap is reached
  bool canShowRewardedAd() {
    if (!shouldShowAds) return false;
    if (!_isRewardedLoaded || _rewardedAd == null) return false;
    _checkRewardedDate();
    return _rewardedAdsShownToday < maxRewardedAdsPerDay;
  }

  /// Returns the number of remaining rewarded ad opportunities today.
  int get remainingRewardedAds {
    _checkRewardedDate();
    final remaining = maxRewardedAdsPerDay - _rewardedAdsShownToday;
    return remaining.clamp(0, maxRewardedAdsPerDay);
  }

  /// Returns the message shown to the user for the rewarded ad offer.
  ///
  /// "Watch an ad and get 5 extra messages!" in Darija.
  String getRewardedAdOfferMessage() {
    return 'Shuf l-i3lan w khud $rewardedBonusMessages messages zaydin!';
  }

  /// Shows a rewarded ad and returns whether the user completed it.
  ///
  /// If the user watches the full ad, returns `true` and the caller should
  /// grant [rewardedBonusMessages] extra AI responses. If the user skips
  /// or the ad fails, returns `false`.
  ///
  /// After the ad closes (regardless of outcome), a new rewarded ad is
  /// pre-loaded.
  Future<bool> showRewardedAd() async {
    if (!canShowRewardedAd()) {
      dev.log(
        'Cannot show rewarded ad (loaded: $_isRewardedLoaded, '
        'today: $_rewardedAdsShownToday/$maxRewardedAdsPerDay)',
        name: _tag,
      );
      return false;
    }

    final completer = Completer<bool>();
    bool rewardEarned = false;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) {
        dev.log('Rewarded ad shown', name: _tag);
      },
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        dev.log(
          'Rewarded ad dismissed (reward earned: $rewardEarned)',
          name: _tag,
        );
        ad.dispose();
        _rewardedAd = null;
        _isRewardedLoaded = false;
        _loadRewardedAd(); // Pre-load the next one.
        completer.complete(rewardEarned);
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        dev.log(
          'Rewarded ad failed to show: ${error.message}',
          name: _tag,
          error: error,
        );
        ad.dispose();
        _rewardedAd = null;
        _isRewardedLoaded = false;
        _loadRewardedAd();
        completer.complete(false);
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        dev.log(
          'User earned reward: ${reward.amount} ${reward.type}',
          name: _tag,
        );
        rewardEarned = true;
        _rewardedAdsShownToday++;
      },
    );

    return completer.future;
  }

  // ---------------------------------------------------------------------------
  // Sacred moment protection
  // ---------------------------------------------------------------------------

  /// Notifies the ad service that the user has entered a "sacred moment."
  ///
  /// During sacred moments (calls, check-ins, typing), no ads should be
  /// shown. The service won't serve interstitial or rewarded ads while
  /// this flag is active.
  ///
  /// Call [endSacredMoment] when the moment ends.
  bool _inSacredMoment = false;

  /// Whether the user is currently in a sacred moment (no ads allowed).
  bool get isInSacredMoment => _inSacredMoment;

  /// Marks the start of a sacred moment (call, check-in, etc.).
  ///
  /// While in a sacred moment, [shouldShowInterstitial] and
  /// [canShowRewardedAd] will return false.
  void beginSacredMoment() {
    _inSacredMoment = true;
    dev.log('Sacred moment started -- ads suppressed', name: _tag);
  }

  /// Marks the end of a sacred moment.
  void endSacredMoment() {
    _inSacredMoment = false;
    dev.log('Sacred moment ended -- ads resumed', name: _tag);
  }

  // ---------------------------------------------------------------------------
  // Date tracking for rewarded ads
  // ---------------------------------------------------------------------------

  /// Checks if the rewarded ad counter should reset (new day).
  void _checkRewardedDate() {
    final now = DateTime.now();
    if (now.year != _rewardedAdsDate.year ||
        now.month != _rewardedAdsDate.month ||
        now.day != _rewardedAdsDate.day) {
      _rewardedAdsDate = now;
      _rewardedAdsShownToday = 0;
      dev.log('Rewarded ad daily counter reset', name: _tag);
    }
  }

  // ---------------------------------------------------------------------------
  // Dispose
  // ---------------------------------------------------------------------------

  /// Cleans up all ad resources.
  ///
  /// Call this when the ad service is no longer needed (e.g., app exit
  /// or when the user upgrades to a paid tier).
  void dispose() {
    dev.log('Disposing ad service', name: _tag);

    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerLoaded = false;

    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialLoaded = false;

    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isRewardedLoaded = false;

    _isInitialized = false;
    _inSacredMoment = false;
  }

  // ---------------------------------------------------------------------------
  // Debug
  // ---------------------------------------------------------------------------

  /// Returns a debug summary of the ad service state.
  String debugSummary() {
    _checkRewardedDate();
    final buffer = StringBuffer()
      ..writeln('--- AdService Debug ---')
      ..writeln('Initialized: $_isInitialized')
      ..writeln('Should show ads: $shouldShowAds')
      ..writeln('Banner loaded: $_isBannerLoaded')
      ..writeln('Interstitial loaded: $_isInterstitialLoaded')
      ..writeln('Rewarded loaded: $_isRewardedLoaded')
      ..writeln('In sacred moment: $_inSacredMoment')
      ..writeln('Rewarded shown today: $_rewardedAdsShownToday/$maxRewardedAdsPerDay')
      ..writeln('Last interstitial: $_lastInterstitialTime')
      ..writeln('Banner ad unit: $bannerAdUnitId')
      ..writeln('Interstitial ad unit: $interstitialAdUnitId')
      ..writeln('Rewarded ad unit: $rewardedAdUnitId');
    return buffer.toString();
  }
}
