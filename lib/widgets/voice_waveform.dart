import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A simplified voice waveform visualization widget for the Dostok app.
///
/// Displays a row of animated bars with varying heights to represent
/// audio input.
///
/// Usage:
/// ```dart
/// VoiceWaveform(
///   isActive: true,
///   barCount: 5,
///   color: AppColors.primary,
/// )
/// ```
class VoiceWaveform extends StatefulWidget {
  final bool isActive;
  final int barCount;
  final Color? color;
  final double height;
  final double barWidth;
  final double spacing;

  const VoiceWaveform({
    super.key,
    this.isActive = true,
    this.barCount = 5,
    this.color,
    this.height = 40,
    this.barWidth = 4,
    this.spacing = 3,
  });

  @override
  State<VoiceWaveform> createState() => _VoiceWaveformState();
}

class _VoiceWaveformState extends State<VoiceWaveform>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _controllers = List.generate(
      widget.barCount,
      (index) => AnimationController(
        duration: Duration(milliseconds: 400 + _random.nextInt(300)),
        vsync: this,
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.2,
        end: 0.8 + _random.nextDouble() * 0.2,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));
    }).toList();

    if (widget.isActive) {
      _startAnimations();
    }
  }

  void _startAnimations() {
    for (var i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  void _stopAnimations() {
    for (var controller in _controllers) {
      controller.stop();
      controller.reset();
    }
  }

  @override
  void didUpdateWidget(VoiceWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.barCount != oldWidget.barCount) {
      _disposeControllers();
      _initializeAnimations();
    }
    if (widget.isActive && !oldWidget.isActive) {
      _startAnimations();
    } else if (!widget.isActive && oldWidget.isActive) {
      _stopAnimations();
    }
  }

  void _disposeControllers() {
    for (var controller in _controllers) {
      controller.dispose();
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final barColor = widget.color ?? theme.colorScheme.primary;

    return SizedBox(
      height: widget.height,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          widget.barCount,
          (index) => _buildAnimatedBar(index, barColor),
        ),
      ),
    );
  }

  Widget _buildAnimatedBar(int index, Color color) {
    return AnimatedBuilder(
      animation: _animations[index],
      builder: (context, child) {
        return Container(
          width: widget.barWidth,
          height: widget.height * _animations[index].value,
          margin: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.7 + (_animations[index].value * 0.3)),
            borderRadius: BorderRadius.circular(widget.barWidth / 2),
          ),
        );
      },
    );
  }
}
