import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../widgets/hikmah_app_bar.dart';

class MeTab extends ConsumerWidget {
  const MeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const HikmahAppBar(
        title: 'بارك الله فيك',
        showStorage: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.md),
        children: [
          // ─── VIP CARD ───
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withValues(alpha: 0.7),
                  theme.colorScheme.tertiary.withValues(alpha: 0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(AppDimensions.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hikmah User',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.workspace_premium,
                                  size: 14,
                                  color: Colors.black87,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'FREE',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.settings_outlined,
                        color: Colors.white70,
                      ),
                      onPressed: () {
                        context.push(RouteNames.settings);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _VipStat(count: '128', label: 'Videos'),
                    _VipStatDivider(),
                    _VipStat(count: '256', label: 'Songs'),
                    _VipStatDivider(),
                    _VipStat(count: '15', label: 'Playlists'),
                    _VipStatDivider(),
                    _VipStat(count: '42', label: 'Favorites'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.lg),

          // ─── FEATURES GRID ───
          Text(
            'Features',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimensions.md),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.9,
            children: [
              _FeatureTile(
                icon: Icons.favorite,
                color: Colors.red,
                label: 'Favorites',
                onTap: () => context.push(RouteNames.favorites),
              ),
              _FeatureTile(
                icon: Icons.history,
                color: Colors.blue,
                label: 'History',
                onTap: () => context.push(RouteNames.history),
              ),
              _FeatureTile(
                icon: Icons.download_done,
                color: Colors.green,
                label: 'Downloads',
                onTap: () {},
              ),
              _FeatureTile(
                icon: Icons.timer_outlined,
                color: Colors.orange,
                label: 'Sleep Timer',
                onTap: () {},
              ),
              _FeatureTile(
                icon: Icons.equalizer,
                color: Colors.purple,
                label: 'Equalizer',
                onTap: () {},
              ),
              _FeatureTile(
                icon: Icons.cast_outlined,
                color: Colors.teal,
                label: 'Cast',
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.lg),

          // ─── SETTINGS LIST ───
          Text(
            'Settings',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimensions.sm),
          _SettingsTile(
            icon: Icons.palette_outlined,
            title: 'Theme',
            subtitle: 'Dark mode, colors',
            onTap: () => context.push(RouteNames.settingsTheme),
          ),
          _SettingsTile(
            icon: Icons.play_circle_outline,
            title: 'Playback',
            subtitle: 'Speed, resume, auto-play',
            onTap: () => context.push(RouteNames.settingsPlayback),
          ),
          _SettingsTile(
            icon: Icons.storage_outlined,
            title: 'Storage',
            subtitle: 'Cache, scan, hidden folders',
            onTap: () => context.push(RouteNames.settingsStorage),
          ),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Media controls',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.language,
            title: 'Language',
            subtitle: 'English',
            onTap: () {},
          ),
          const Divider(height: 32),
          _SettingsTile(
            icon: Icons.info_outline,
            title: 'About',
            subtitle: 'Version 1.0.0',
            onTap: () => context.push(RouteNames.settingsAbout),
          ),
          _SettingsTile(
            icon: Icons.feedback_outlined,
            title: 'Feedback',
            subtitle: 'Report bugs, suggest features',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.star_outline,
            title: 'Rate App',
            subtitle: 'Support us on the store',
            onTap: () {},
          ),
          const SizedBox(height: AppDimensions.xxl),
          Center(
            child: Text(
              'Made with ❤️ and Hikmah',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.md),
        ],
      ),
    );
  }
}

// ─── VIP Stat ───
class _VipStat extends StatelessWidget {
  final String count;
  final String label;

  const _VipStat({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _VipStatDivider extends StatelessWidget {
  const _VipStatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      color: Colors.white.withValues(alpha: 0.3),
    );
  }
}

// ─── Feature Tile ───
class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _FeatureTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Settings Tile ───
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
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 20,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: theme.colorScheme.onSurfaceVariant,
        size: 20,
      ),
    );
  }
}