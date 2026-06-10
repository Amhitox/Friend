import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../providers/chat_provider.dart';
import '../providers/user_provider.dart';
import '../theme/app_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundFor(context),
      body: const _HomeBody(),
    );
  }
}

class _HomeBody extends StatefulWidget {
  const _HomeBody();

  @override
  State<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<_HomeBody> with TickerProviderStateMixin {
  late final AnimationController _shimmerController;
  late final AnimationController _blobController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _blobController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _blobController.dispose();
    super.dispose();
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good Morning';
    if (hour >= 12 && hour < 17) return 'Good Afternoon';
    if (hour >= 17 && hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  String _statusQuote() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return "You're doing great today.";
    } else if (hour >= 12 && hour < 17) {
      return "Take a breath. I'm right here.";
    } else if (hour >= 17 && hour < 21) {
      return "Wind down whenever you're ready.";
    }
    return "Rest easy. I'll be here in the morning.";
  }

  String _formatRelativeTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}';
  }

  @override
  Widget build(BuildContext context) {
    final userName =
        context.watch<UserProvider>().currentUser?.name ?? 'Friend';
    final chatProvider = context.watch<ChatProvider>();
    final textPrimary = AppColors.textPrimaryFor(context);
    final textSecondary = AppColors.textSecondaryFor(context);
    final surface = AppColors.surfaceFor(context);
    final primaryContainer = AppColors.primaryContainerFor(context);
    final cardShadow = AppColors.cardShadowFor(context);
    final lastMessage =
        chatProvider.messages.isNotEmpty ? chatProvider.messages.last : null;

    return Stack(
      children: [
        // ── Ambient background blobs ──
        _buildBlob(
          top: -60,
          left: -60,
          size: 220,
          color: AppColors.primary.withValues(alpha: 0.06),
          phase: 0,
        ),
        _buildBlob(
          bottom: 100,
          right: -80,
          size: 260,
          color: AppColors.secondary.withValues(alpha: 0.04),
          phase: math.pi,
        ),
        _buildBlob(
          top: 180,
          right: -40,
          size: 160,
          color: AppColors.primary.withValues(alpha: 0.04),
          phase: math.pi * 0.5,
        ),

        // ── Content ──
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),

                // ── Greeting + Settings ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_greeting()}, $userName',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                              height: 1.3,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _statusQuote(),
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/settings'),
                      icon: Icon(
                        Icons.settings_outlined,
                        size: 22,
                        color: textSecondary,
                      ),
                      splashRadius: 20,
                    ),
                  ],
                ).animate().fadeIn(delay: 100.ms, duration: 600.ms).slideY(
                      begin: 0.15,
                      end: 0,
                      duration: 600.ms,
                      curve: Curves.easeOut,
                    ),

                const SizedBox(height: 40),

                // ── Primary Action ──
                Container(
                  height: 64,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppColors.elevatedShadow,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pushNamed(context, '/chat'),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // shimmer sweep
                            Positioned.fill(
                              child: AnimatedBuilder(
                                animation: _shimmerController,
                                builder: (context, child) {
                                  final v = _shimmerController.value;
                                  return Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white.withValues(
                                            alpha: 0.0,
                                          ),
                                          Colors.white.withValues(
                                            alpha: 0.15,
                                          ),
                                          Colors.white.withValues(
                                            alpha: 0.0,
                                          ),
                                        ],
                                        stops: [
                                          (v - 0.25).clamp(0.0, 1.0),
                                          v.clamp(0.0, 1.0),
                                          (v + 0.25).clamp(0.0, 1.0),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Chat Now!',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    height: 1.2,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 250.ms, duration: 700.ms).slideY(
                      begin: 0.15,
                      end: 0,
                      duration: 700.ms,
                      curve: Curves.easeOut,
                    ),

                const SizedBox(height: 16),

                // ── Secondary Actions ──
                Row(
                  children: [
                    Expanded(
                      child: _GlassCard(
                        icon: Icons.mic_outlined,
                        label: 'Voice Call',
                        onTap: () => Navigator.pushNamed(context, '/call'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _GlassCard(
                        icon: Icons.wb_sunny_outlined,
                        label: 'Daily Check-in',
                        onTap: () => Navigator.pushNamed(context, '/daily'),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 400.ms, duration: 600.ms).slideY(
                      begin: 0.15,
                      end: 0,
                      duration: 600.ms,
                      curve: Curves.easeOut,
                    ),

                const SizedBox(height: 24),

                // ── Recent Conversation Preview ──
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/chat'),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: cardShadow,
                    ),
                    child: lastMessage != null
                        ? Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: primaryContainer,
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  'D',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Dostok',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: textPrimary,
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      lastMessage.content,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: textSecondary,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatRelativeTime(lastMessage.timestamp),
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  color: textSecondary,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.chevron_right,
                                size: 16,
                                color: textSecondary,
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: primaryContainer,
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  'D',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'No messages yet. Say hi!',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: textSecondary,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_forward,
                                size: 16,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                  ),
                ).animate().fadeIn(delay: 550.ms, duration: 600.ms).slideY(
                      begin: 0.15,
                      end: 0,
                      duration: 600.ms,
                      curve: Curves.easeOut,
                    ),

                const SizedBox(height: 24),

                const Spacer(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBlob({
    double? top,
    double? left,
    double? bottom,
    double? right,
    required double size,
    required Color color,
    required double phase,
  }) {
    return Positioned(
      top: top,
      left: left,
      bottom: bottom,
      right: right,
      child: AnimatedBuilder(
        animation: _blobController,
        builder: (context, child) {
          final t = _blobController.value * 2 * math.pi + phase;
          return Transform.translate(
            offset: Offset(
              math.sin(t) * 18,
              math.cos(t * 0.7) * 14,
            ),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _GlassCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context)
            .withValues(alpha: AppColors.isDark(context) ? 0.92 : 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.dividerFor(context).withValues(alpha: 0.6),
          width: 1,
        ),
        boxShadow: AppColors.cardShadowFor(context),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 28, color: AppColors.primary),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryFor(context),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
