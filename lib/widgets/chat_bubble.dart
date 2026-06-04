import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../models/message.dart';
import '../theme/app_colors.dart';

/// A premium chat bubble widget styled for the Dostok app.
///
/// Renders messages with different styles for user (right-aligned, purple)
/// and AI (left-aligned, white) messages. Supports timestamps below bubbles,
/// an avatar on AI messages, long-press copy, and animated entrance.
///
/// Usage:
/// ```dart
/// ChatBubble(message: message)
/// ```
class ChatBubble extends StatelessWidget {
  /// The message model containing text, timestamp, sender, and metadata.
  final Message message;

  /// Optional animation controller for the entrance animation.
  final AnimationController? animationController;

  const ChatBubble({
    super.key,
    required this.message,
    this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    if (message.type == MessageType.system) {
      return _buildSystemMessage(context);
    }

    final isUser = message.isFromUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const userBubbleColor = AppColors.bubbleUser;
    final aiBubbleColor = isDark ? const Color(0xFF1E1E1E) : AppColors.bubbleAi;
    const userTextColor = Colors.white;
    final aiTextColor = isDark ? Colors.white.withOpacity(0.92) : AppColors.textPrimary;

    final bubbleColor = isUser ? userBubbleColor : aiBubbleColor;
    final textColor = isUser ? userTextColor : aiTextColor;

    Widget bubble = Padding(
      padding: EdgeInsets.only(
        left: isUser ? 48 : 12,
        right: isUser ? 12 : 48,
        top: 4,
        bottom: 4,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            _buildAvatar(),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onLongPress: () => _copyToClipboard(context),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.72,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(isUser ? 20 : 4),
                        topRight: Radius.circular(isUser ? 4 : 20),
                        bottomLeft: const Radius.circular(20),
                        bottomRight: const Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _buildMessageContent(textColor, isUser),
                  ),
                ),
                const SizedBox(height: 4),
                _buildTimestamp(isUser),
              ],
            ),
          ),
        ],
      ),
    );

    if (animationController != null) {
      final slideAnimation = Tween<Offset>(
        begin: isUser ? const Offset(0.3, 0) : const Offset(-0.3, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animationController!,
        curve: Curves.easeOutCubic,
      ));

      final fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: animationController!,
        curve: Curves.easeIn,
      ));

      return SlideTransition(
        position: slideAnimation,
        child: FadeTransition(
          opacity: fadeAnimation,
          child: bubble,
        ),
      );
    }

    return bubble;
  }

  Widget _buildAvatar() {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: AppColors.primaryContainer,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Text(
        'D',
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildMessageContent(Color textColor, bool isUser) {
    if (message.type == MessageType.audio) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.play_arrow_rounded,
            size: 20,
            color: isUser ? Colors.white70 : AppColors.primary,
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) {
              return Container(
                width: 3,
                height: 4 + (i % 3) * 4.0,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isUser
                      ? Colors.white.withOpacity(0.5)
                      : AppColors.primary.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
          const SizedBox(width: 8),
          Text(
            message.content,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              color: isUser ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
        ],
      );
    }

    return Text(
      message.content,
      style: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textColor,
        height: 1.35,
      ),
    );
  }

  Widget _buildTimestamp(bool isUser) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          DateFormat('HH:mm').format(message.timestamp),
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 10,
            fontWeight: FontWeight.w400,
            color: isUser ? Colors.white.withOpacity(0.7) : AppColors.textSecondary,
          ),
        ),
        if (isUser) ...[
          const SizedBox(width: 4),
          Icon(
            message.isRead ? Icons.done_all : Icons.done,
            size: 12,
            color: message.isRead ? const Color(0xFF64B5F6) : AppColors.textSecondary,
          ),
        ],
      ],
    );
  }

  Widget _buildSystemMessage(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message.content,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            color: isDark ? Colors.white54 : Colors.black45,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message.content));
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Message copied',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
