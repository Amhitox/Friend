import 'package:flutter/material.dart';

/// A simplified premium badge widget.
///
/// TODO: Remove if no longer needed.
class PremiumBadge extends StatelessWidget {
  final String label;
  final Color color;
  final double size;

  const PremiumBadge({
    super.key,
    this.label = 'Premium',
    this.color = const Color(0xFF8B7BF7),
    this.size = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star_rounded,
          size: size,
          color: color,
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: size * 0.75,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ],
    );
  }
}
