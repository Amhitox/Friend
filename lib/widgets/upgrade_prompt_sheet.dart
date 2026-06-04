import 'package:flutter/material.dart';

/// Stub: UpgradePromptSheet is no longer used. Kept to avoid breaking imports.
///
/// TODO: Remove this file and its exports once all imports are cleaned up.
class UpgradePromptSheet extends StatelessWidget {
  const UpgradePromptSheet({super.key});

  static Future<void> show(
    BuildContext context, {
    required dynamic limitType,
    int? remaining,
    String? featureName,
    VoidCallback? onUpgradePremium,
    VoidCallback? onUpgradeVIP,
    VoidCallback? onWatchAd,
    VoidCallback? onDismiss,
    bool isFirstShow = true,
  }) async {
    // No-op
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
