import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../models/message.dart';

/// A chat bubble widget styled for the Dostok app.
///
/// Renders messages with different styles for user (right-aligned, teal)
/// and AI (left-aligned, dark) messages. Supports RTL text direction,
/// timestamps, long-press copy, and animated entrance via [SlideTransition]
/// + [FadeTransition].
///
/// Usage:
/// ```dart
/// // Standalone (no animation)
/// ChatBubble(message: message)
///
/// // With entrance animation (provide an AnimationController)
/// ChatBubble(
///   message: message,
///   animationController: myController,
/// )
/// ```
class ChatBubble extends StatelessWidget {
  /// The message model containing text, timestamp, sender, and metadata.
  final Message message;

  /// Optional animation controller for the entrance animation.
  /// When provided the bubble slides in from the appropriate side and fades in.
  final AnimationController? animationController;

  const ChatBubble({
    super.key,
    required this.message,
    this.animationController,
  });

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // System messages are rendered as centered muted captions.
    if (message.type == MessageType.system) {
      return _buildSystemMessage(context);
    }

    final isUser = message.isFromUser;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // -- Colours ---------------------------------------------------------------
    final userBubbleColor =
        isDark ? const Color(0xFF5B4BD6) : const Color(0xFF7C6BF5);
    final aiBubbleColor =
        isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);
    final userTextColor = Colors.white;
    final aiTextColor =
        isDark ? Colors.white.withOpacity(0.92) : Colors.black87;
    final timestampColor =
        isUser ? Colors.white60 : (isDark ? Colors.white38 : Colors.black38);
    final tailColor = isUser
        ? (isDark ? const Color(0xFF4B3FA8) : const Color(0xFF6B5AE0))
        : (isDark ? const Color(0xFF171717) : const Color(0xFFEEEEEE));

    final bubbleColor = isUser ? userBubbleColor : aiBubbleColor;
    final textColor = isUser ? userTextColor : aiTextColor;

    // -- Bubble body -----------------------------------------------------------
    Widget bubble = Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _copyToClipboard(context),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          margin: EdgeInsets.only(
            left: isUser ? 48 : 12,
            right: isUser ? 12 : 48,
            top: 2,
            bottom: 2,
          ),
          child: CustomPaint(
            painter: _BubbleTailPainter(
              isUser: isUser,
              bubbleColor: tailColor,
            ),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Audio indicator for voice messages
                  if (message.type == MessageType.audio) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.mic,
                          size: 16,
                          color: isUser
                              ? Colors.white70
                              : const Color(0xFF7C6BF5),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            message.content,
                            style: GoogleFonts.cairo(
                              fontSize: 15,
                              color: textColor,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        message.content,
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          color: textColor,
                          height: 1.35,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  // Timestamp + read receipts
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(message.timestamp),
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: timestampColor,
                        ),
                      ),
                      if (isUser) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 14,
                          color: message.isRead
                              ? const Color(0xFF64B5F6)
                              : timestampColor,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // -- Entrance animation ----------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // System message
  // ---------------------------------------------------------------------------

  Widget _buildSystemMessage(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message.content,
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            fontSize: 13,
            color: isDark ? Colors.white54 : Colors.black45,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Clipboard
  // ---------------------------------------------------------------------------

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message.content));
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Nsa-kh l-message',
          style: GoogleFonts.cairo(),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// =============================================================================
// Bubble tail painter
// =============================================================================

/// Draws a small triangular tail at the bottom corner of the bubble.
class _BubbleTailPainter extends CustomPainter {
  final bool isUser;
  final Color bubbleColor;

  _BubbleTailPainter({required this.isUser, required this.bubbleColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = bubbleColor
      ..style = PaintingStyle.fill;

    final path = Path();
    if (isUser) {
      path.moveTo(size.width - 4, size.height - 8);
      path.lineTo(size.width + 4, size.height + 2);
      path.lineTo(size.width - 14, size.height - 4);
    } else {
      path.moveTo(4, size.height - 8);
      path.lineTo(-4, size.height + 2);
      path.lineTo(14, size.height - 4);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter oldDelegate) =>
      oldDelegate.isUser != isUser ||
      oldDelegate.bubbleColor != bubbleColor;
}
