import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/chat_provider.dart';
import '../services/stt_service.dart';
import '../services/subscription_service.dart';
import '../services/ad_service.dart';
import '../services/analytics_service.dart';
import '../models/subscription.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/usage_indicator.dart';
import '../widgets/upgrade_prompt_sheet.dart';
import '../widgets/premium_badge.dart';

/// The main chat screen for Dostok.
///
/// This is the heart of the app -- a WhatsApp-quality chat interface with a
/// warm Moroccan aesthetic. It manages message display, text/voice input,
/// typing indicators, and smooth animations throughout.
///
/// Monetization integration:
/// - UsageIndicator in AppBar shows remaining messages for free tier
/// - Before sending: checks canSendMessage() from SubscriptionService
/// - If at limit: shows UpgradePromptSheet instead of sending
/// - If near limit (80%+): shows subtle warning
/// - After sending: records message in SubscriptionService
/// - Interstitial ad logic: shows after every 15th message
/// - Premium badge next to Dostok name for premium users
/// - "Priority response" indicator for premium/VIP
/// - Rewarded ad prompt when at limit
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with TickerProviderStateMixin {
  // ---------------------------------------------------------------------------
  // Controllers & state
  // ---------------------------------------------------------------------------

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();

  late final AnimationController _sendButtonController;
  late final Animation<double> _sendButtonScale;

  final STTService _sttService = STTService();

  bool _hasText = false;
  bool _isRecording = false;
  bool _showScrollToBottom = false;
  int _previousMessageCount = 0;

  /// Session message count for interstitial ad frequency tracking.
  int _sessionMessageCount = 0;

  /// Timestamp of last message send, used to avoid showing interstitials
  /// between rapid messages.
  DateTime? _lastMessageTime;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    // Send button pulse animation.
    _sendButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _sendButtonScale = CurvedAnimation(
      parent: _sendButtonController,
      curve: Curves.easeOutBack,
    );

    _textController.addListener(_onTextChanged);
    _scrollController.addListener(_onScroll);

    // Load persisted messages once.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadMessages();
      AnalyticsService().logScreenView('chat_screen');
    });
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _inputFocusNode.dispose();
    _sendButtonController.dispose();
    _sttService.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Text & scroll listeners
  // ---------------------------------------------------------------------------

  void _onTextChanged() {
    final hasText = _textController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
      if (hasText) {
        _sendButtonController.forward();
      } else {
        _sendButtonController.reverse();
      }
    }
  }

  void _onScroll() {
    // Show "scroll to bottom" FAB when user scrolls up more than 300px.
    if (!_scrollController.hasClients) return;
    final distanceFromBottom =
        _scrollController.position.maxScrollExtent - _scrollController.offset;
    final shouldShow = distanceFromBottom > 300;
    if (shouldShow != _showScrollToBottom) {
      setState(() => _showScrollToBottom = shouldShow);
    }
  }

  // ---------------------------------------------------------------------------
  // Auto-scroll
  // ---------------------------------------------------------------------------

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      if (animated) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Send & voice actions (with monetization checks)
  // ---------------------------------------------------------------------------

  Future<void> _sendTextMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final subService = context.read<SubscriptionService>();

    // Check if user can send a message (AI response quota).
    if (!subService.canReceiveAiResponse()) {
      _showUpgradeOrRewardedAd(subService);
      return;
    }

    // If near limit (80%+), show subtle warning.
    final remaining = subService.remainingMessages;
    if (remaining > 0 && remaining != -1) {
      final maxMessages = subService.limits.maxAiResponsesPerDay;
      if (maxMessages > 0) {
        final used = maxMessages - remaining;
        if (used / maxMessages >= 0.8) {
          _showSnackBar('$remaining messages b9aw lyoum');
        }
      }
    }

    _textController.clear();
    setState(() => _hasText = false);
    _sendButtonController.reverse();

    // Unfocus keyboard after sending.
    _inputFocusNode.unfocus();

    await context.read<ChatProvider>().sendMessage(text);

    // Record the message in subscription service.
    await subService.recordMessage();
    _sessionMessageCount++;
    _lastMessageTime = DateTime.now();

    // Analytics.
    AnalyticsService().logMessageSent(messageType: 'text', length: text.length);

    // Check for interstitial ad opportunity.
    _checkInterstitialAd(subService);

    _scrollToBottom();
  }

  Future<void> _toggleVoiceInput() async {
    if (_isRecording) {
      // Stop recording and send.
      await _sttService.stopListening();
      setState(() => _isRecording = false);
      final text = _textController.text.trim();
      if (text.isNotEmpty) {
        final subService = context.read<SubscriptionService>();

        // Check if user can receive AI response.
        if (!subService.canReceiveAiResponse()) {
          _showUpgradeOrRewardedAd(subService);
          return;
        }

        _textController.clear();
        await context.read<ChatProvider>().sendMessage(text);

        // Record the message.
        await subService.recordMessage();
        _sessionMessageCount++;
        _lastMessageTime = DateTime.now();

        AnalyticsService().logMessageSent(
          messageType: 'voice',
          length: text.length,
        );

        _checkInterstitialAd(subService);
        _scrollToBottom();
      }
    } else {
      // Start recording.
      final started = await _sttService.startListening((result) {
        if (mounted) {
          setState(() {
            _textController.text = result;
            _textController.selection = TextSelection.fromPosition(
              TextPosition(offset: result.length),
            );
            _hasText = result.trim().isNotEmpty;
          });
        }
      });
      if (started && mounted) {
        setState(() => _isRecording = true);
      } else if (mounted) {
        _showSnackBar('Ma tqderch tsm3. Jerrab mrra khra.');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Monetization helpers
  // ---------------------------------------------------------------------------

  /// Shows UpgradePromptSheet or rewarded ad option when at message limit.
  void _showUpgradeOrRewardedAd(SubscriptionService subService) {
    AnalyticsService().logPaywallShown(
      trigger: 'message_limit',
      placement: 'chat',
    );

    UpgradePromptSheet.show(
      context,
      limitType: LimitType.messageLimit,
      remaining: 0,
      onUpgradePremium: () {
        Navigator.of(context).pop();
        Navigator.of(context).pushNamed('/paywall', arguments: {
          'highlightFeature': 'unlimited_messages',
        });
      },
      onUpgradeVIP: () {
        Navigator.of(context).pop();
        Navigator.of(context).pushNamed('/paywall', arguments: {
          'highlightFeature': 'unlimited_messages',
        });
      },
      onWatchAd: () {
        Navigator.of(context).pop();
        _handleRewardedAd(subService);
      },
      onDismiss: () {
        AnalyticsService().logPaywallDismissed(placement: 'chat');
      },
    );
  }

  /// Handles the rewarded ad flow for earning bonus messages.
  Future<void> _handleRewardedAd(SubscriptionService subService) async {
    // AdService is a singleton-like service; we get it from the provider tree.
    // For this integration, we show a snackbar guiding the user.
    // In a full implementation, AdService.showRewardedAd() would be called.
    _showSnackBar('Shuf l-i3lan w khud 5 messages?');

    // The actual rewarded ad flow:
    // final earned = await adService.showRewardedAd();
    // if (earned) { grant extra messages }
    AnalyticsService().logFeatureUsed(featureName: 'rewarded_ad_prompt');
  }

  /// Checks whether an interstitial ad should be shown after a message.
  void _checkInterstitialAd(SubscriptionService subService) {
    if (subService.isPremium) return; // No ads for premium users.

    // Only show after every 15th message.
    if (_sessionMessageCount % AdService.interstitialFrequency != 0) return;

    // Don't show between rapid messages (at least 2 minutes gap).
    if (_lastMessageTime != null) {
      final elapsed = DateTime.now().difference(_lastMessageTime!);
      if (elapsed.inSeconds < AdService.minInterstitialGapSeconds) return;
    }

    // In a full implementation, AdService.showInterstitialAd() would be called.
    AnalyticsService().logAdShown(
      adType: 'interstitial',
      placement: 'chat',
    );
  }

  // ---------------------------------------------------------------------------
  // Menu actions
  // ---------------------------------------------------------------------------

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _buildMenuOption(
                ctx,
                icon: Icons.phone_rounded,
                label: 'Call Dostok',
                onTap: () {
                  Navigator.pop(ctx);
                  _navigateToCall();
                },
              ),
              _buildMenuOption(
                ctx,
                icon: Icons.delete_outline_rounded,
                label: 'Msa7 l-klam',
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmClearChat();
                },
              ),
              _buildMenuOption(
                ctx,
                icon: Icons.info_outline_rounded,
                label: '3la Dostok',
                onTap: () {
                  Navigator.pop(ctx);
                  _showAboutSheet();
                },
              ),
              const Gap(12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF7C6BF5)),
      title: Text(
        label,
        style: GoogleFonts.cairo(fontSize: 16),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
    );
  }

  void _navigateToCall() {
    // Navigate to CallScreen if the route exists; otherwise show a placeholder.
    try {
      Navigator.pushNamed(context, '/call');
    } catch (_) {
      _showSnackBar('CallScreen machi mawjoud ba9i.');
    }
  }

  void _confirmClearChat() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Msa7 l-klam?', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: Text(
          'Ghaytl3 kulshi. Ma tqderch trje3 l-wara.',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('La', style: GoogleFonts.cairo()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ChatProvider>().clearChat();
            },
            child: Text(
              'Msa7',
              style: GoogleFonts.cairo(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.chat_bubble_rounded,
                  size: 48, color: Color(0xFF7C6BF5)),
              const Gap(12),
              Text(
                'Dostok',
                style: GoogleFonts.cairo(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Gap(8),
              Text(
                'Sahbek li kihder meak b-ddarija.\nVersion 1.0.0',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const Gap(24),
            ],
          ),
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo()),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0E0E0E) : const Color(0xFFF0EDE6),
      appBar: _buildAppBar(isDark),
      body: Column(
        children: [
          // Chat area (messages list).
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, _) {
                // Auto-scroll when new messages arrive.
                if (chatProvider.messageCount > _previousMessageCount) {
                  _previousMessageCount = chatProvider.messageCount;
                  _scrollToBottom();
                }

                return _buildChatBody(chatProvider, isDark);
              },
            ),
          ),

          // Input area.
          _buildInputArea(isDark),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // AppBar (with UsageIndicator and Premium badge)
  // ---------------------------------------------------------------------------

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFF7C6BF5),
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.15),
      leadingWidth: 56,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: AvatarGlow(
          glowColor: const Color(0xFFC77DFF),
          endRadius: 40.0,
          animate: true,
          child: CircleAvatar(
            radius: 20,
            backgroundColor: isDark ? Colors.white12 : Colors.white24,
            child: Icon(
              Icons.smart_toy_rounded,
              color: isDark ? const Color(0xFFC77DFF) : Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
      title: Consumer<SubscriptionService>(
        builder: (context, subService, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Dostok',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  // Premium badge next to Dostok name.
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
              // Typing indicator or priority response indicator.
              Consumer<ChatProvider>(
                builder: (context, chat, _) {
                  if (chat.isTyping) {
                    return Text(
                      'kateb...',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    );
                  }
                  // Show "Priority response" for premium/VIP.
                  if (subService.canUseFeature('priorityResponse')) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.speed_rounded,
                          size: 12,
                          color: const Color(0xFFA5D6A7),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Priority response',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: const Color(0xFFA5D6A7),
                          ),
                        ),
                      ],
                    );
                  }
                  return Text(
                    'online',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: const Color(0xFFA5D6A7),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
      actions: [
        // UsageIndicator in AppBar for free users.
        Consumer<SubscriptionService>(
          builder: (context, subService, _) {
            if (subService.isPremium) return const SizedBox.shrink();
            final remaining = subService.remainingMessages;
            final max = subService.limits.maxAiResponsesPerDay;
            if (max <= 0 || remaining == -1) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Center(
                child: UsageIndicator(
                  current: max - remaining,
                  max: max,
                  label: 'rassayil',
                  unit: 'rassila',
                  style: UsageIndicatorStyle.circular,
                  icon: Icons.chat_bubble_rounded,
                ),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.call_rounded, color: Colors.white),
          tooltip: 'Call Dostok',
          onPressed: _navigateToCall,
        ),
        IconButton(
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
          tooltip: 'Options',
          onPressed: _showOptionsMenu,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Chat body -- loading, empty, error, or message list
  // ---------------------------------------------------------------------------

  Widget _buildChatBody(ChatProvider chatProvider, bool isDark) {
    // Loading shimmer on first load.
    if (chatProvider.isLoading && chatProvider.isEmpty) {
      return const ChatLoadingShimmer();
    }

    // Error state with retry.
    if (chatProvider.error != null && chatProvider.isEmpty) {
      return _buildErrorState(chatProvider, isDark);
    }

    // Empty state.
    if (chatProvider.isEmpty) {
      return _buildEmptyState(isDark);
    }

    // Message list.
    return Stack(
      children: [
        _buildMessageList(chatProvider, isDark),
        // Subtle top gradient for depth.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Container(
              height: 24,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    isDark ? const Color(0xFF0E0E0E) : const Color(0xFFF0EDE6),
                    (isDark ? const Color(0xFF0E0E0E) : const Color(0xFFF0EDE6))
                        .withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Scroll-to-bottom FAB.
        if (_showScrollToBottom)
          Positioned(
            right: 16,
            bottom: 8,
            child: FloatingActionButton.small(
              backgroundColor: isDark ? Colors.grey.shade800 : Colors.white,
              foregroundColor: const Color(0xFF7C6BF5),
              elevation: 3,
              onPressed: () => _scrollToBottom(),
              child: const Icon(Icons.keyboard_arrow_down_rounded),
            ),
          ).animate().fadeIn(duration: 200.ms).scale(begin: const Offset(0.8, 0.8)),
      ],
    );
  }

  Widget _buildMessageList(ChatProvider chatProvider, bool isDark) {
    final messages = chatProvider.messages;
    final showTyping = chatProvider.isTyping;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 12),
      // +1 for the typing indicator at the bottom.
      itemCount: messages.length + (showTyping ? 1 : 0),
      itemBuilder: (context, index) {
        // Typing indicator at the end.
        if (showTyping && index == messages.length) {
          return const TypingIndicator(label: null);
        }

        final message = messages[index];

        // Date separator if this is the first message or the day changed.
        final showDate = index == 0 ||
            !_isSameDay(message.timestamp, messages[index - 1].timestamp);

        return Column(
          children: [
            if (showDate) _buildDateSeparator(message.timestamp, isDark),
            ChatBubble(message: message)
                .animate()
                .fadeIn(
                  duration: 300.ms,
                  delay: const Duration(milliseconds: 50),
                )
                .slideX(
                  begin: message.isFromUser ? 0.08 : -0.08,
                  end: 0,
                  duration: 300.ms,
                  curve: Curves.easeOutCubic,
                ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Empty state
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.waving_hand_rounded,
              size: 64,
              color: const Color(0xFFC77DFF),
            ),
            const Gap(16),
            Text(
              'Salam! Ana Dostok',
              style: GoogleFonts.cairo(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const Gap(8),
            Text(
              'Kteb-li shi haja wla sm3ni b-sotek',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 16,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
            const Gap(32),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip('Labas 3lik?'),
                _buildSuggestionChip('Shno katdir?'),
                _buildSuggestionChip('Hder meaya'),
              ],
            ),
          ],
        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return ActionChip(
      label: Text(
        text,
        style: GoogleFonts.cairo(
          color: const Color(0xFF7C6BF5),
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: const Color(0xFF7C6BF5).withOpacity(0.1),
      side: BorderSide(color: const Color(0xFF7C6BF5).withOpacity(0.3)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: () {
        _textController.text = text;
        _sendTextMessage();
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Error state
  // ---------------------------------------------------------------------------

  Widget _buildErrorState(ChatProvider chatProvider, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 64,
              color: Colors.grey,
            ),
            const Gap(16),
            Text(
              chatProvider.error ?? 'Shi haja mshat ghalat.',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 16,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const Gap(24),
            ElevatedButton.icon(
              onPressed: () => chatProvider.loadMessages(),
              icon: const Icon(Icons.refresh_rounded),
              label: Text('Jerrab mrra khra', style: GoogleFonts.cairo()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C6BF5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  // ---------------------------------------------------------------------------
  // Date separator
  // ---------------------------------------------------------------------------

  Widget _buildDateSeparator(DateTime date, bool isDark) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(date.year, date.month, date.day);

    String label;
    if (messageDay == today) {
      label = 'Lyom';
    } else if (messageDay == today.subtract(const Duration(days: 1))) {
      label = 'Lbare7';
    } else {
      label = '${date.day}/${date.month}/${date.year}';
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 12,
            color: isDark ? Colors.white54 : Colors.black45,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ---------------------------------------------------------------------------
  // Input area
  // ---------------------------------------------------------------------------

  Widget _buildInputArea(bool isDark) {
    final bgColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final inputBg = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF7F5FF);
    final borderColor = isDark ? Colors.white12 : Colors.black12;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Voice / mic button.
              _buildMicButton(isDark),
              const Gap(6),

              // Text input field.
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  decoration: BoxDecoration(
                    color: inputBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Gap(14),
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          focusNode: _inputFocusNode,
                          maxLines: 5,
                          minLines: 1,
                          textInputAction: TextInputAction.newline,
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Kteb shi haja...',
                            hintStyle: GoogleFonts.cairo(
                              fontSize: 15,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onSubmitted: (_) => _sendTextMessage(),
                        ),
                      ),
                      // Emoji placeholder (future).
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6, right: 4),
                        child: Icon(
                          Icons.emoji_emotions_outlined,
                          size: 24,
                          color:
                              isDark ? Colors.white30 : Colors.black26,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Gap(6),

              // Send button with scale animation.
              _buildSendButton(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMicButton(bool isDark) {
    return GestureDetector(
      onLongPress: () {
        // Long press to cancel recording.
        if (_isRecording) {
          _sttService.cancel();
          setState(() {
            _isRecording = false;
            _textController.clear();
            _hasText = false;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _isRecording
              ? Colors.red.withOpacity(0.15)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
              key: ValueKey(_isRecording),
              color: _isRecording
                  ? Colors.red
                  : (isDark ? Colors.white60 : Colors.black45),
              size: 24,
            ),
          ),
          onPressed: _toggleVoiceInput,
          tooltip: _isRecording ? 'Stop recording' : 'Voice input',
        ),
      ),
    );
  }

  Widget _buildSendButton(bool isDark) {
    return ScaleTransition(
      scale: _sendButtonScale,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _hasText
              ? const Color(0xFF7C6BF5)
              : (isDark ? Colors.white12 : Colors.grey.shade200),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) =>
                RotationTransition(turns: anim, child: child),
            child: Icon(
              _hasText ? Icons.send_rounded : Icons.thumb_up_alt_outlined,
              key: ValueKey(_hasText),
              color: _hasText
                  ? Colors.white
                  : (isDark ? Colors.white38 : Colors.black38),
              size: 20,
            ),
          ),
          onPressed: _hasText ? _sendTextMessage : null,
          tooltip: 'Send',
        ),
      ),
    );
  }
}
