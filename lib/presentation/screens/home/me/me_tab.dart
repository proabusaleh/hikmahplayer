import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_dimensions.dart';

class MeTab extends ConsumerWidget {
  const MeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.75),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            Text(
              'Hikmah',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
            Text(
              ' Player',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w400,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.md),
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.15),
                  theme.colorScheme.primary.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
            ),
            padding: const EdgeInsets.all(AppDimensions.lg),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.play_arrow_rounded, size: 28, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hikmah Player',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Premium Experience',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.lg),

          Text(
            'Tools',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppDimensions.sm),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.85,
            children: [
              _FeatureTile(icon: Icons.download_rounded, label: 'Downloads', onTap: () {}),
              _FeatureTile(icon: Icons.folder_rounded, label: 'Media', onTap: () {}),
              _FeatureTile(icon: Icons.lock_rounded, label: 'Privacy', onTap: () {}),
              _FeatureTile(icon: Icons.share_rounded, label: 'Transfer', onTap: () {}),
              _FeatureTile(icon: Icons.palette_rounded, label: 'Theme', onTap: () => context.push(RouteNames.settingsTheme)),
              _FeatureTile(icon: Icons.history_rounded, label: 'History', onTap: () => context.push(RouteNames.history)),
            ],
          ),

          const SizedBox(height: AppDimensions.lg),

          Text(
            'Settings',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppDimensions.sm),
          _SettingsTile(
            icon: Icons.palette_outlined,
            title: 'Appearance',
            subtitle: 'Theme, colors, fonts',
            onTap: () => context.push(RouteNames.settingsTheme),
          ),
          _SettingsTile(
            icon: Icons.play_circle_outline,
            title: 'Playback',
            subtitle: 'Speed, resume, video fit',
            onTap: () => context.push(RouteNames.settingsPlayback),
          ),
          _SettingsTile(
            icon: Icons.storage_outlined,
            title: 'Storage',
            subtitle: 'Cache, scan, folders',
            onTap: () => context.push(RouteNames.settingsStorage),
          ),
          _SettingsTile(
            icon: Icons.subtitles_rounded,
            title: 'Subtitles',
            subtitle: 'Size, font, color',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.graphic_eq,
            title: 'Audio',
            subtitle: 'Equalizer, output',
            onTap: () {},
          ),
          const Divider(height: 32),
          _SettingsTile(
            icon: Icons.info_outline,
            title: 'About Hikmah Player',
            subtitle: 'Version 1.0.0',
            onTap: () => context.push(RouteNames.settingsAbout),
          ),
          _SettingsTile(
            icon: Icons.help_outline_rounded,
            title: 'Help & Feedback',
            subtitle: 'Report bugs, suggest features',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.star_outline_rounded,
            title: 'Rate Us',
            subtitle: 'Support us on the store',
            onTap: () {},
          ),
          const SizedBox(height: AppDimensions.xxl),
          Center(
            child: Text(
              'Made with ❤️ and Hikmah',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.md),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FeatureTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
      ),
      title: Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      trailing: Icon(Icons.chevron_right_rounded, size: 18, color: theme.colorScheme.onSurfaceVariant),
    );
  }
}
