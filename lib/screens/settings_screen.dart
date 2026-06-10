import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/daily_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Settings Screen
// ─────────────────────────────────────────────────────────────────────────────

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  SharedPreferences? _prefs;
  double _speed = 0.5;
  double _pitch = 1.0;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _speed = (_prefs?.getDouble('ttsSpeed') ?? 0.5).clamp(0.3, 1.0);
      _pitch = (_prefs?.getDouble('ttsPitch') ?? 1.0).clamp(0.5, 2.0);
    });
  }

  // ── UI helpers ──

  Widget _buildIconContainer(IconData icon,
      {Color? containerColor, Color? iconColor}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: containerColor ?? AppColors.primaryContainerFor(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        color: iconColor ?? AppColors.primary,
        size: 20,
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondaryFor(context),
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildSwitchRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            _buildIconContainer(icon),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryFor(context),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondaryFor(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            CupertinoSwitch(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required String trailingText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIconContainer(icon),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryFor(context),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondaryFor(context),
                  ),
                ),
                const SizedBox(height: 8),
                Slider(
                  value: value,
                  min: min,
                  max: max,
                  onChanged: onChanged,
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.primary.withValues(alpha: 0.2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 44,
            child: Text(
              trailingText,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDestructiveRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            _buildIconContainer(
              icon,
              containerColor: AppColors.errorContainerFor(context),
              iconColor: AppColors.error,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondaryFor(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondaryFor(context),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            _buildIconContainer(icon),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryFor(context),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondaryFor(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondaryFor(context),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required String trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          _buildIconContainer(icon),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryFor(context),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondaryFor(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            trailing,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondaryFor(context),
            ),
          ),
        ],
      ),
    );
  }

  // ── Dialogs ──

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceFor(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Clear all data?',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryFor(context),
          ),
        ),
        content: Text(
          'This will erase all conversations, settings, and your profile. This cannot be undone.',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            color: AppColors.textSecondaryFor(context),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondaryFor(context),
              ),
            ),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final userProv = context.read<UserProvider>();
              final dailyProv = context.read<DailyProvider>();
              await userProv.clearProfile();
              await dailyProv.clearTasks();
              await dailyProv.clearMood();
              await Hive.deleteBoxFromDisk('settings');
              await Hive.deleteBoxFromDisk('conversations');
              final sp = await SharedPreferences.getInstance();
              await sp.clear();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'All data cleared',
                      style: TextStyle(fontFamily: 'Cairo'),
                    ),
                    backgroundColor: AppColors.primary,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Clear',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppColors.textPrimaryFor(context),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimaryFor(context),
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          // ── Notifications ──
          _buildSectionHeader('Notifications'),
          _buildSwitchRow(
            icon: Icons.notifications_rounded,
            title: 'Push Notifications',
            subtitle: 'Receive push notifications from the app',
            value: _prefs?.getBool('pushNotifications') ?? true,
            onChanged: (v) async {
              setState(() {});
              await _prefs?.setBool('pushNotifications', v);
            },
          ),
          Divider(
            height: 1,
            color: AppColors.dividerFor(context),
            indent: 56,
          ),
          _buildSwitchRow(
            icon: Icons.today_rounded,
            title: 'Daily Reminder',
            subtitle: 'Get a daily reminder to chat',
            value: _prefs?.getBool('dailyReminder') ?? true,
            onChanged: (v) async {
              setState(() {});
              await _prefs?.setBool('dailyReminder', v);
            },
          ),
          Divider(
            height: 1,
            color: AppColors.dividerFor(context),
            indent: 56,
          ),
          _buildSwitchRow(
            icon: Icons.volume_up_rounded,
            title: 'Sound Effects',
            subtitle: 'Play sounds for messages and actions',
            value: _prefs?.getBool('soundEffects') ?? true,
            onChanged: (v) async {
              setState(() {});
              await _prefs?.setBool('soundEffects', v);
            },
          ),

          const SizedBox(height: 32),

          // ── Voice ──
          _buildSectionHeader('Voice'),
          _buildSliderRow(
            icon: Icons.speed_rounded,
            title: 'Speech Speed',
            subtitle: 'Adjust how fast Dostok speaks',
            value: _speed,
            min: 0.3,
            max: 1.0,
            onChanged: (v) {
              setState(() => _speed = v);
              _prefs?.setDouble('ttsSpeed', v);
            },
            trailingText: '${(_speed * 100).round()}%',
          ),
          Divider(
            height: 1,
            color: AppColors.dividerFor(context),
            indent: 56,
          ),
          _buildSliderRow(
            icon: Icons.tune_rounded,
            title: 'Speech Pitch',
            subtitle: 'Adjust the pitch of Dostok\'s voice',
            value: _pitch,
            min: 0.5,
            max: 2.0,
            onChanged: (v) {
              setState(() => _pitch = v);
              _prefs?.setDouble('ttsPitch', v);
            },
            trailingText: _pitch.toStringAsFixed(1),
          ),

          const SizedBox(height: 32),

          // ── Appearance ──
          _buildSectionHeader('Appearance'),
          _buildSwitchRow(
            icon: themeProv.isDarkMode
                ? Icons.dark_mode_rounded
                : Icons.light_mode_rounded,
            title: 'Dark Mode',
            subtitle: themeProv.isDarkMode
                ? 'Dark theme enabled'
                : 'Light theme enabled',
            value: themeProv.isDarkMode,
            onChanged: (_) => themeProv.toggleTheme(),
          ),

          const SizedBox(height: 32),

          // ── Data & Privacy ──
          _buildSectionHeader('Data & Privacy'),
          _buildDestructiveRow(
            icon: Icons.delete_outline_rounded,
            title: 'Clear All Data',
            subtitle: 'Erase conversations, settings, and profile',
            onTap: _showClearDataDialog,
          ),
          Divider(
            height: 1,
            color: AppColors.dividerFor(context),
            indent: 56,
          ),
          _buildNavigationRow(
            icon: Icons.policy_rounded,
            title: 'Privacy Policy',
            subtitle: 'Read our privacy policy',
            onTap: () {},
          ),

          const SizedBox(height: 32),

          // ── About ──
          _buildSectionHeader('About'),
          _buildInfoRow(
            icon: Icons.info_outline_rounded,
            title: 'App Version',
            subtitle: 'Current app version',
            trailing: 'Version 1.0.0',
          ),

          const SizedBox(height: 48),

          // ── Footer ──
          Center(
            child: Text(
              'Made with ❤️ in Morocco',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondaryFor(context),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
