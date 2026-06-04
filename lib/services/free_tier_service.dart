import 'dart:developer' as dev;

import 'subscription_service.dart';

/// Manages the enjoyable-but-limited free tier experience for Dostok.
///
/// The philosophy: free users should genuinely love the app. Limits feel like
/// "I want more" rather than "this is broken." Messages are warm, Darija-first,
/// and frame upgrades as unlocking fun rather than removing features.
///
/// Always-free features:
/// - Unlimited text message sends (AI responses limited to 20/day)
/// - Basic Dostok personality (the default warm friend)
/// - 1 daily check-in (morning)
/// - Relationship meter
/// - Dark mode
/// - Basic mood tracking
///
/// Usage:
/// ```dart
/// final freeTier = FreeTierService(subscriptionService);
///
/// // On app open for a free user
/// final welcome = freeTier.getFreeWelcomeMessage();
///
/// // After each AI response
/// final remaining = freeTier.getRemainingAiResponses();
/// if (freeTier.shouldShowUpgradeNudge(messageCount)) {
///   showUpgradeSheet(freeTier.getUpgradeMotivation());
/// }
/// ```
class FreeTierService {
  // ---------------------------------------------------------------------------
  // Constants
  // ---------------------------------------------------------------------------

  /// Tag for debug logging.
  static const String _tag = 'FreeTierService';

  /// Maximum AI responses per day for free users.
  ///
  /// 20 is enough for a genuinely good conversation -- not stingy, but enough
  /// to make the user want more by evening.
  static const int freeDailyAiResponses = 20;

  /// Call minutes per day for free users.
  ///
  /// Zero -- calls are premium only. But we show a teaser so users know
  /// the feature exists and can desire it.
  static const int freeCallMinutesPerDay = 0;

  /// Number of personalities available to free users.
  ///
  /// Just the default Dostok personality. Enough to build a bond, but custom
  /// personalities are a strong premium draw.
  static const int freePersonalities = 1;

  /// Daily check-ins available to free users.
  ///
  /// One morning check-in. Enough to establish the habit, but premium users
  /// get evening and on-demand check-ins too.
  static const int freeDailyCheckins = 1;

  /// Strategic nudge points -- message counts at which we show upgrade hints.
  ///
  /// These are carefully spaced:
  /// - After 10 messages: mid-conversation, user is engaged, soft hint
  /// - After 15 messages: user has had a good session, moderate hint
  /// - After 18 messages: near limit, stronger hint with specific benefit
  static const List<int> _nudgePoints = [10, 15, 18];

  // ---------------------------------------------------------------------------
  // Dependencies
  // ---------------------------------------------------------------------------

  final SubscriptionService _subscriptionService;

  /// Tracks which nudge points have already been shown today.
  final Set<int> _shownNudgePoints = {};

  // ---------------------------------------------------------------------------
  // Constructor
  // ---------------------------------------------------------------------------

  /// Creates a [FreeTierService] bound to the given [SubscriptionService].
  FreeTierService(this._subscriptionService);

  // ---------------------------------------------------------------------------
  // Welcome & daily messages
  // ---------------------------------------------------------------------------

  /// Returns the welcome message shown to a new or returning free user.
  ///
  /// Generous in tone -- sets the expectation that this is a real, enjoyable
  /// experience, not a crippled demo. Mentions limits transparently but
  /// frames them positively.
  String getFreeWelcomeMessage() {
    return 'Ahlan bik f Dostok! Ana sadiqek li kayhder Darija. '
        '3andek $freeDailyAiResponses message lyoum -- khlliha mzyana '
        'w ghadi tn3ss bi l-fra7. Yallah, kifash nqdro n3awnouk?';
  }

  /// Returns the message shown when daily limits reset at midnight.
  ///
  /// Fresh start, positive energy. This should feel like a gift, not a
  /// reminder of constraints.
  String getDailyResetMessage() {
    return 'Sbah lkher! 3andek $freeDailyAiResponses message lyoum. '
        'Khlliha mzyana! Kifash ghadi nbdaw l-youm?';
  }

  /// Returns a friendly nudge when the user is approaching their daily limit.
  ///
  /// [remaining] is the number of AI responses left. The tone scales:
  /// - 5-10 remaining: gentle reminder, no pressure
  /// - 2-4 remaining: warmer, mentions premium casually
  /// - 1 remaining: most direct, but still friendly
  /// - 0 remaining: tomorrow message, no upgrade pressure
  String getNearLimitMessage(int remaining) {
    if (remaining <= 0) {
      return 'Slaamt! St3mliw kolchi l-youm. '
          'Ghda 3awd 3andek $freeDailyAiResponses message jdod. '
          'Nshoufouk ghda!';
    }

    if (remaining == 1) {
      return 'Qddamk message wa7da! St3mlha mzyana. '
          'Bghiti tktar? Premium 3andek kolchi bla 7doud.';
    }

    if (remaining <= 4) {
      return 'Qddamk $remaining messages barka. '
          'Mn lwel w hna m3ak, walakin ila bghiti t7der m3aya aktar, '
          'Premium ghadi y7l lik kolchi.';
    }

    // 5-10 remaining
    return 'Mazal 3andek $remaining message lyoum. '
        'M3akom nqdro ndwiw mzyan!';
  }

  /// Returns context-aware upgrade motivation tailored to user behavior.
  ///
  /// The message changes based on what the user seems to value most.
  /// Always in Darija, always warm, never pushy.
  ///
  /// If no specific context is detected, returns the general upgrade pitch.
  String getUpgradeMotivation({UpgradeContext context = UpgradeContext.general}) {
    switch (context) {
      case UpgradeContext.general:
        return 'Bghiti tktar? Premium 3andek kolchi -- messages bla 7doud, '
            'calls m3a Dostok, w personalités jdod. Jrbha mzyana!';

      case UpgradeContext.moreMessages:
        return 'Kayban lik l-conversation mzyana! Premium ma 3andou 7doud '
            'f messages -- hder m3a Dostok 3la rassek bla ma tfekker f l-3dad.';

      case UpgradeContext.calls:
        return 'Dostok yqder yhder m3ak b ssot! Premium 3andek '
            '30 dqiqa f nhar, w VIP 120 dqiqa. Jrb chi call w chouf l-far9.';

      case UpgradeContext.personalities:
        return 'Bghiti Dostok ykoun 3la moujoud? Premium ykhalik tkhliq '
            'personality jdida -- 7dar, 7azen, comedian... nta li tqarrar.';

      case UpgradeContext.checkins:
        return 'L-check-in sbeh mzyan, walakin m3a Premium ghadi t3mel '
            'check-in f sso w f lil. Zid mood analytics bach tchouf kifash '
            'ghaydir nharik 3la jra.';

      case UpgradeContext.adFree:
        return 'Bghiti tkhlli l-conversation ndhifa? VIP ma 3andou i3lanat '
            'koulchi. Hder m3a Dostok bla ma yq3d chi 7aja.';

      case UpgradeContext.vip:
        return 'VIP howa l-experience kamla -- voice cloning, proactive messages, '
            'kolchi bla 7doud w bla i3lanat. Dostok ghadi ykoun sa7bek l-haqiqi.';
    }
  }

  // ---------------------------------------------------------------------------
  // Strategic nudge timing
  // ---------------------------------------------------------------------------

  /// Determines whether an upgrade nudge should be shown at this message count.
  ///
  /// Nudge timing is strategic, not annoying:
  /// - Only at predefined [nudgePoints] (10, 15, 18)
  /// - Each nudge point is shown at most once per day
  /// - Never during the first 9 messages -- let the user enjoy the app
  /// - Never after limit is reached (handled separately)
  ///
  /// [messageCount] is today's total AI response count.
  bool shouldShowUpgradeNudge(int messageCount) {
    if (messageCount <= 0) return false;

    // Find the highest nudge point that this message count qualifies for.
    int? targetPoint;
    for (final point in _nudgePoints) {
      if (messageCount >= point) {
        targetPoint = point;
      }
    }

    if (targetPoint == null) return false;

    // Only show if we haven't already shown this nudge point today.
    if (_shownNudgePoints.contains(targetPoint)) return false;

    _shownNudgePoints.add(targetPoint);
    dev.log(
      'Upgrade nudge triggered at message $messageCount '
      '(point: $targetPoint)',
      name: _tag,
    );
    return true;
  }

  // ---------------------------------------------------------------------------
  // Usage queries
  // ---------------------------------------------------------------------------

  /// Returns the number of AI responses remaining today for a free user.
  ///
  /// Returns 0 if the limit has been reached.
  int getRemainingAiResponses() {
    final usage = _subscriptionService.currentUsage;
    final remaining = freeDailyAiResponses - usage.aiResponsesReceived;
    return remaining.clamp(0, freeDailyAiResponses);
  }

  /// Returns the number of call minutes remaining today for a free user.
  ///
  /// Always 0 for free tier -- calls are premium only.
  int getRemainingCallMinutes() {
    return freeCallMinutesPerDay;
  }

  /// Whether the free user can still receive AI responses today.
  bool canReceiveAiResponse() {
    return getRemainingAiResponses() > 0;
  }

  /// Whether the free user can make a call.
  ///
  /// Always false for free tier, but used to show the call teaser UI.
  bool canMakeCall() {
    return false;
  }

  /// Whether the user has used up all their AI responses for today.
  bool isDailyLimitReached() {
    return getRemainingAiResponses() <= 0;
  }

  /// Returns a progress value (0.0 to 1.0) representing how much of the
  /// daily AI allowance has been used.
  ///
  /// Useful for progress bars or visual indicators.
  double getUsageProgress() {
    final usage = _subscriptionService.currentUsage;
    final used = usage.aiResponsesReceived;
    return (used / freeDailyAiResponses).clamp(0.0, 1.0);
  }

  /// Returns a summary string for the status bar or profile screen.
  ///
  /// Example: "14/20 AI messages today"
  String getUsageSummary() {
    final usage = _subscriptionService.currentUsage;
    final used = usage.aiResponsesReceived.clamp(0, freeDailyAiResponses);
    return '$used/$freeDailyAiResponses AI messages today';
  }

  // ---------------------------------------------------------------------------
  // Call teaser
  // ---------------------------------------------------------------------------

  /// Returns a teaser message for the voice call feature.
  ///
  /// Free users can't make calls, but we show them what they're missing
  /// in an enticing way.
  String getCallTeaserMessage() {
    return 'Calls m3a Dostok? Ghadi ykoun mzyan! '
        'Upgrade l Premium bach t7der m3a Dostok b ssot.';
  }

  /// Returns the title for the call teaser button/card.
  String getCallTeaserTitle() {
    return 'Jrb chi call m3a Dostok!';
  }

  // ---------------------------------------------------------------------------
  // Limit-reached experience
  // ---------------------------------------------------------------------------

  /// Returns the message shown when the user hits zero AI responses.
  ///
  /// This is the most critical moment. It must not feel punishing. The message
  /// acknowledges the fun they had, offers tomorrow's reset, and gently
  /// presents upgrade as an option (not a requirement).
  String getLimitReachedMessage() {
    final usage = _subscriptionService.currentUsage;
    final sent = usage.messagesSent;

    return 'Slaamt 3la l-youm! Hdert m3ak $sent message. '
        'Ghda 3awd 3andek $freeDailyAiResponses message jdod.\n\n'
        'Ila ma bqiti tsta9der tssnna, Premium ma 3andou 7doud '
        '-- w 3andek calls, personalités, w bzaf dyal l-7wayj.';
  }

  /// Returns a short, dismissable message for the "limit reached" card.
  ///
  /// Even shorter than [getLimitReachedMessage] -- for use in tight UI spots
  /// like inline banners.
  String getLimitReachedShort() {
    return 'St3mliw kolchi l-youm! Ghda message jdod.';
  }

  // ---------------------------------------------------------------------------
  // Personality teaser
  // ---------------------------------------------------------------------------

  /// Returns a teaser for the custom personalities feature.
  ///
  /// Free users only have the default Dostok. This teases the possibility
  /// of different personality types.
  String getPersonalityTeaser() {
    return 'Dostok howa sadiqek l-asasi. M3a Premium, ymkn lik tkhliq '
        'personalités jdod -- 7dar, funny, calm... chno bghiti?';
  }

  // ---------------------------------------------------------------------------
  // Reset
  // ---------------------------------------------------------------------------

  /// Resets the daily nudge tracking.
  ///
  /// Call this at midnight or when daily usage resets, so nudge points
  /// can be shown again the next day.
  void resetDailyNudges() {
    _shownNudgePoints.clear();
    dev.log('Daily nudge points reset', name: _tag);
  }

  // ---------------------------------------------------------------------------
  // Debug
  // ---------------------------------------------------------------------------

  /// Returns a debug summary of the free tier service state.
  String debugSummary() {
    final remaining = getRemainingAiResponses();
    final progress = getUsageProgress();
    final buffer = StringBuffer()
      ..writeln('--- FreeTierService Debug ---')
      ..writeln('Daily AI limit: $freeDailyAiResponses')
      ..writeln('Remaining today: $remaining')
      ..writeln('Usage progress: ${(progress * 100).toStringAsFixed(0)}%')
      ..writeln('Limit reached: ${isDailyLimitReached()}')
      ..writeln('Call minutes: $freeCallMinutesPerDay (premium only)')
      ..writeln('Personalities: $freePersonalities')
      ..writeln('Check-ins: $freeDailyCheckins')
      ..writeln('Shown nudges today: $_shownNudgePoints');
    return buffer.toString();
  }
}

/// Context for what the user seems to be interested in, used to tailor
/// upgrade motivation messages.
enum UpgradeContext {
  /// No specific signal -- general upgrade pitch.
  general,

  /// User is sending many messages -- wants more AI responses.
  moreMessages,

  /// User tapped the call feature -- interested in voice calls.
  calls,

  /// User browsed personalities -- interested in customization.
  personalities,

  /// User did a check-in -- interested in emotional features.
  checkins,

  /// User saw an ad -- might want ad-free experience.
  adFree,

  /// User has been active for a while -- might want the full VIP experience.
  vip,
}
