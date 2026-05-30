import 'package:flutter/material.dart';

/// A mood selector widget for the Dostok app.
///
/// Displays a row of emoji buttons with Darija labels. Supports
/// selected state with scale animation and returns the selected mood string.
///
/// Usage:
/// ```dart
/// MoodSelector(
///   onMoodSelected: (mood) {
///     print('Selected mood: $mood');
///   },
/// )
/// ```
class MoodSelector extends StatefulWidget {
  /// Callback when a mood is selected.
  final ValueChanged<String>? onMoodSelected;

  /// Initial selected mood (optional).
  final String? initialMood;

  const MoodSelector({
    super.key,
    this.onMoodSelected,
    this.initialMood,
  });

  @override
  State<MoodSelector> createState() => _MoodSelectorState();
}

class _MoodSelectorState extends State<MoodSelector>
    with SingleTickerProviderStateMixin {
  String? _selectedMood;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  /// Available moods with emojis and Darija labels.
  final List<Map<String, String>> _moods = [
    {'emoji': '😊', 'label': 'Mzyan', 'value': 'happy'},
    {'emoji': '😢', 'label': 'Mghammar', 'value': 'sad'},
    {'emoji': '😤', 'label': 'M3assel', 'value': 'angry'},
    {'emoji': '😴', 'label': '3ayan', 'value': 'tired'},
    {'emoji': '🤔', 'label': 'Mfaker', 'value': 'thinking'},
    {'emoji': '😎', 'label': 'Nice', 'value': 'cool'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedMood = widget.initialMood;

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onMoodTap(String mood) {
    setState(() {
      _selectedMood = mood;
    });

    // Animate selection
    _scaleController.forward().then((_) {
      _scaleController.reverse();
    });

    // Notify callback
    widget.onMoodSelected?.call(mood);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _moods.map((mood) {
            final isSelected = _selectedMood == mood['value'];
            return _buildMoodButton(
              context,
              mood: mood,
              isSelected: isSelected,
              theme: theme,
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Builds a single mood button with emoji and label.
  Widget _buildMoodButton(
    BuildContext context, {
    required Map<String, String> mood,
    required bool isSelected,
    required ThemeData theme,
  }) {
    return GestureDetector(
      onTap: () => _onMoodTap(mood['value']!),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: isSelected ? _scaleAnimation.value : 1.0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        width: 2,
                      )
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Emoji
                  Text(
                    mood['emoji']!,
                    style: TextStyle(
                      fontSize: isSelected ? 32 : 28,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Darija label
                  Text(
                    mood['label']!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
