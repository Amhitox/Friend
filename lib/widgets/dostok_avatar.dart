import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Available avatar sizes for DostokAvatar.
enum AvatarSize {
  small(40),
  medium(60),
  large(100);

  final double value;
  const AvatarSize(this.value);
}

/// A circular avatar widget for the Dostok app.
///
/// Displays a gradient circle with the letter "D" and optional glow effect.
class DostokAvatar extends StatefulWidget {
  final AvatarSize size;
  final bool showGlow;
  final String? status;
  final List<Color>? gradientColors;

  const DostokAvatar({
    super.key,
    this.size = AvatarSize.medium,
    this.showGlow = true,
    this.status,
    this.gradientColors,
  });

  @override
  State<DostokAvatar> createState() => _DostokAvatarState();
}

class _DostokAvatarState extends State<DostokAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    if (widget.showGlow) {
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(DostokAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showGlow && !oldWidget.showGlow) {
      _glowController.repeat(reverse: true);
    } else if (!widget.showGlow && oldWidget.showGlow) {
      _glowController.stop();
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size.value;
    final fontSize = size * 0.4;

    final colors = widget.gradientColors ?? [
      AppColors.primary,
      AppColors.primary.withOpacity(0.7),
      AppColors.primaryDark,
    ];

    return SizedBox(
      width: size + 16,
      height: size + 16,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.showGlow)
            AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                return Container(
                  width: size + (16 * _glowAnimation.value),
                  height: size + (16 * _glowAnimation.value),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary
                            .withOpacity(0.3 * _glowAnimation.value),
                        blurRadius: 20 * _glowAnimation.value,
                        spreadRadius: 5 * _glowAnimation.value,
                      ),
                    ],
                  ),
                );
              },
            ),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
              border: Border.all(
                color: Theme.of(context).colorScheme.surface,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                'D',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (widget.status != null)
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                width: size * 0.25,
                height: size * 0.25,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getStatusColor(widget.status!),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'online':
        return Colors.green;
      case 'away':
        return Colors.orange;
      case 'offline':
      default:
        return Colors.grey;
    }
  }
}
