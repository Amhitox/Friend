import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../providers/daily_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Settings Screen
// ─────────────────────────────────────────────────────────────────────────────

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProv = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parametrat'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Notifications ──
          _SettingsSection(
            title: 'Notifications',
            icon: Icons.notifications_rounded,
            children: [
              _SwitchSetting(
                title: 'Notifications actives',
                subtitle: 'Dir notification ki tbgha chi haja jdida',
                value: true,
                onChanged: (_) {},
              ),
              _SwitchSetting(
                title: 'Daily reminder',
                subtitle: 'Fkirni nhdar m3a Dostok kol nhar',
                value: true,
                onChanged: (_) {},
              ),
              _SwitchSetting(
                title: 'Sound effects',
                subtitle: 'Sma3 sound ki ntl3o message',
                value: false,
                onChanged: (_) {},
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Voice settings ──
          _SettingsSection(
            title: 'Sawt dial Dostok',
            icon: Icons.record_voice_over_rounded,
            children: [
              _SliderSetting(
                title: 'Sur3a dial lhdra',
                subtitle: 'Sh7al t-talka Dostok b sur3a',
                value: _VoiceSettings._speed,
                onChanged: (v) => _VoiceSettings._speed = v,
                labels: const ['Bti7', '3adi', 'Bsra3a'],
              ),
              _SliderSetting(
                title: 'Pitch dial lhdra',
                subtitle: 'Sh7al sot 3ali wla khafi',
                value: _VoiceSettings._pitch,
                onChanged: (v) => _VoiceSettings._pitch = v,
                labels: const ['Ghali9', '3adi', '3ali'],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Data management ──
          _SettingsSection(
            title: 'Data',
            icon: Icons.storage_rounded,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.download_rounded,
                      color: theme.colorScheme.primary, size: 20),
                ),
                title: const Text('Sajjel data diali'),
                subtitle: const Text('Dir backup l conversations dialk'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ghir tbba3... backup')),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.delete_outline_rounded,
                      color: theme.colorScheme.error, size: 20),
                ),
                title: Text(
                  'Msa7 kol data',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                subtitle: const Text('Msa7 kol conversation w data'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _showDeleteDialog(context),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.cached_rounded,
                      color: theme.colorScheme.primary, size: 20),
                ),
                title: const Text('Clear cache'),
                subtitle: const Text('Msa7 cache bach ykhdm mzyan'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cache msa7!')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Privacy ──
          _SettingsSection(
            title: 'Khssosiya',
            icon: Icons.shield_rounded,
            children: [
              _SwitchSetting(
                title: 'Share analytics',
                subtitle: '3awnna nfahmo kifach katsrf l app',
                value: false,
                onChanged: (_) {},
              ),
              _SwitchSetting(
                title: 'Save conversations',
                subtitle: 'Khlli conversations m3a Dostok',
                value: true,
                onChanged: (_) {},
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.policy_rounded,
                      color: theme.colorScheme.primary, size: 20),
                ),
                title: const Text('Privacy policy'),
                subtitle: const Text('Shnu ki ndiro m3a data dialk'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── API Configuration ──
          _SettingsSection(
            title: 'API Configuration',
            icon: Icons.api_rounded,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.key_rounded,
                      color: theme.colorScheme.primary, size: 20),
                ),
                title: const Text('API Key'),
                subtitle: const Text('Sh7al mn API key katsrf'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Connected',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
                onTap: () => _showApiKeyDialog(context),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.language_rounded,
                      color: theme.colorScheme.primary, size: 20),
                ),
                title: const Text('Model AI'),
                subtitle: const Text('Shnu model kantsrf3o'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'GPT-4o',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Theme toggle shortcut ──
          _SettingsSection(
            title: 'Apparence',
            icon: Icons.palette_rounded,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Dark mode'),
                subtitle: Text(
                  themeProv.isDarkMode ? 'Maktoub (Dark)' : 'Nuur (Light)',
                ),
                secondary: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    themeProv.isDarkMode
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    key: ValueKey(themeProv.isDarkMode),
                    color: theme.colorScheme.primary,
                  ),
                ),
                value: themeProv.isDarkMode,
                onChanged: (_) => themeProv.toggleTheme(),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // ── App info footer ──
          Center(
            child: Column(
              children: [
                Text(
                  'Dostok v1.0.0',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Made with ❤️ f Maghrib',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[400],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Delete confirmation dialog ──
  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Msa7 kol data?'),
        content: const Text(
          'Had chi ghadi ymsa7 kol conversation w data. Ma ghadirch undo!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('La, khllih'),
          ),
          FilledButton(
            onPressed: () {
              context.read<UserProvider>().clearProfile();
              context.read<DailyProvider>().clearTasks();
              context.read<DailyProvider>().clearMood();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data msa7!')),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Msa7'),
          ),
        ],
      ),
    );
  }

  // ── API key dialog ──
  void _showApiKeyDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Dir API key dialk hna:'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'sk-...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.key_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Lghi'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('API Key t7afd!')),
              );
            },
            child: const Text('Hfd'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// In-memory voice settings (not yet persisted)
// ─────────────────────────────────────────────────────────────────────────────

class _VoiceSettings {
  static double _speed = 0.5;
  static double _pitch = 0.5;
}

// ─────────────────────────────────────────────────────────────────────────────
// Settings Section
// ─────────────────────────────────────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Switch Setting
// ─────────────────────────────────────────────────────────────────────────────

class _SwitchSetting extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchSetting({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: Colors.grey[600]),
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Slider Setting
// ─────────────────────────────────────────────────────────────────────────────

class _SliderSetting extends StatelessWidget {
  final String title;
  final String subtitle;
  final double value;
  final ValueChanged<double> onChanged;
  final List<String> labels;

  const _SliderSetting({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.bodyMedium),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: value,
                  onChanged: onChanged,
                  divisions: labels.length - 1,
                ),
              ),
              Text(
                labels[(value * (labels.length - 1)).round()],
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
