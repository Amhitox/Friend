import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../providers/theme_provider.dart';
import '../models/user_profile.dart';
import 'settings_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Profile Screen
// ─────────────────────────────────────────────────────────────────────────────

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProv = context.watch<UserProvider>();
    final themeProv = context.watch<ThemeProvider>();

    final profile = userProv.currentUser;
    final avatarPath = profile?.avatarPath;
    final name = userProv.displayName;
    final daysActive = profile?.daysActive ?? 0;
    final totalMessages = profile?.totalMessages ?? 0;
    final relationshipLevel = profile?.relationshipLevel ?? 0;
    final currentLang = userProv.preferredLanguage;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Header ──
          Text(
            'Profil diali',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // ── Avatar + Name ──
          Center(
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: avatarPath != null
                          ? ClipOval(
                              child: Image.asset(avatarPath,
                                  fit: BoxFit.cover, width: 104, height: 104),
                            )
                          : Icon(Icons.person_rounded,
                              size: 52, color: theme.colorScheme.primary),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.surface,
                            width: 3,
                          ),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Icon(Icons.edit_rounded,
                            size: 16, color: theme.colorScheme.onPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sahbi f Dostok mn $daysActive nhar',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ── Preferred language selector ──
          _SectionCard(
            title: 'Logha li kandwiha',
            icon: Icons.language_rounded,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: PreferredLanguage.values.map((lang) {
                  final selected = currentLang == lang;
                  return _LanguageChip(
                    label: _languageLabel(lang),
                    selected: selected,
                    onTap: () =>
                        userProv.updateProfile(preferredLanguage: lang),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Relationship stats ──
          _SectionCard(
            title: 'M3a Dostok',
            icon: Icons.favorite_rounded,
            children: [
              Row(
                children: [
                  _MiniStat(
                    value: '$daysActive',
                    label: 'Nhar m3a b3diyyatna',
                    icon: Icons.calendar_today_rounded,
                  ),
                  const SizedBox(width: 12),
                  _MiniStat(
                    value: '$totalMessages',
                    label: 'Message',
                    icon: Icons.message_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Relationship level bar
              Row(
                children: [
                  Text(
                    'Level dial relationship',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$relationshipLevel/100',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (relationshipLevel / 100).clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: theme.colorScheme.surfaceContainerLow,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Theme toggle ──
          _SectionCard(
            title: 'Apparence',
            icon: Icons.palette_rounded,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Dark mode'),
                subtitle: Text(
                  themeProv.isDarkMode ? 'Maktoub (Dark)' : 'Nuur (Light)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
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
          const SizedBox(height: 16),

          // ── Dostok personality ──
          _SectionCard(
            title: 'Shakhsiya dial Dostok',
            icon: Icons.smart_toy_rounded,
            children: [
              if (profile != null) ...[
                _PersonalityRow(
                  trait: 'D7k (Humor)',
                  value: '${profile.humorLevel}/10',
                  icon: Icons.sentiment_very_satisfied_rounded,
                ),
                const Divider(height: 16),
                _PersonalityRow(
                  trait: 'Ta3atuf (Empathy)',
                  value: '${profile.empathyLevel}/10',
                  icon: Icons.volunteer_activism_rounded,
                ),
                const Divider(height: 16),
                _PersonalityRow(
                  trait: 'Formality',
                  value: '${profile.formalityLevel}/10',
                  icon: Icons.record_voice_over_rounded,
                ),
              ] else
                Text(
                  'Mazal m3raft ta haja 3lik',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // ── About ──
          _SectionCard(
            title: '3la Dostok',
            icon: Icons.info_outline_rounded,
            children: [
              _InfoRow(label: 'Version', value: '1.0.0'),
              const Divider(height: 16),
              _InfoRow(label: 'Built with', value: 'Flutter + wld lblad'),
              const Divider(height: 16),
              _InfoRow(label: 'License', value: 'MIT'),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Made with ❤️ f Maghrib',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Settings button ──
          FilledButton.tonalIcon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            icon: const Icon(Icons.settings_rounded),
            label: const Text('Kol parametrat'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  String _languageLabel(PreferredLanguage lang) {
    switch (lang) {
      case PreferredLanguage.darija:
        return 'Darija';
      case PreferredLanguage.arabic:
        return '3rbi';
      case PreferredLanguage.french:
        return 'Francais';
      case PreferredLanguage.mixed:
        return 'Mixed';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Card
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
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
// Language Chip
// ─────────────────────────────────────────────────────────────────────────────

class _LanguageChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mini Stat
// ─────────────────────────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _MiniStat({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Personality Row
// ─────────────────────────────────────────────────────────────────────────────

class _PersonalityRow extends StatelessWidget {
  final String trait;
  final String value;
  final IconData icon;

  const _PersonalityRow({
    required this.trait,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(trait,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  )),
              Text(value, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info Row
// ─────────────────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
