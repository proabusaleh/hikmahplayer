import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../ai_features/presentation/screens/ai_hub_screen.dart';
import '../../../audio/presentation/screens/audio_home_screen.dart';
import '../../../continuity/presentation/screens/continuity_screen.dart';
import '../../../creative/presentation/screens/create_hub_screen.dart';
import '../../../developer/presentation/screens/developer_hub_screen.dart';
import '../../../privacy/presentation/screens/privacy_dashboard_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _Section(
            title: 'Appearance & Playback',
            tiles: [
              _SettingsTile(
                icon: Icons.palette_outlined,
                title: 'Theme',
                subtitle: 'Light, dark, system, accent color',
                onTap: () => context.push('/home/settings/theme'),
              ),
              _SettingsTile(
                icon: Icons.play_circle_outline,
                title: 'Playback',
                subtitle: 'Resume, speed, video fit, loop',
                onTap: () => context.push('/home/settings/playback'),
              ),
            ],
          ),
          _Section(
            title: 'Audio',
            tiles: [
              _SettingsTile(
                icon: Icons.graphic_eq,
                title: 'Audio Engine',
                subtitle: 'DSP, output device, bit-perfect',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AudioHomeScreen()),
                ),
              ),
              _SettingsTile(
                icon: Icons.cell_tower,
                title: 'Cast & Streaming',
                subtitle: 'DLNA, AirPlay, Chromecast',
                onTap: () {},
              ),
            ],
          ),
          _Section(
            title: 'Library',
            tiles: [
              _SettingsTile(
                icon: Icons.folder_open,
                title: 'Media Folders',
                subtitle: 'Scan roots & exclusions',
                onTap: () => context.go('/home/folders'),
              ),
              _SettingsTile(
                icon: Icons.cloud_sync_outlined,
                title: 'Cross-Device',
                subtitle: 'Sync, handoff, universal remote',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ContinuityScreen()),
                ),
              ),
            ],
          ),
          _Section(
            title: 'Tools',
            tiles: [
              _SettingsTile(
                icon: Icons.auto_awesome_outlined,
                title: 'Learn Hub',
                subtitle: 'AI summaries, flashcards, chapters',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AiHubScreen()),
                ),
              ),
              _SettingsTile(
                icon: Icons.content_cut_outlined,
                title: 'Create Studio',
                subtitle: 'Clips, exports, creative tools',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreateHubScreen()),
                ),
              ),
            ],
          ),
          _Section(
            title: 'Privacy & Accessibility',
            tiles: [
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy',
                subtitle: 'Incognito, vault, permissions',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PrivacyDashboardScreen()),
                ),
              ),
              _SettingsTile(
                icon: Icons.accessibility_new,
                title: 'Accessibility',
                subtitle: 'Colour filters, gestures, TTS',
                onTap: () {},
              ),
            ],
          ),
          _Section(
            title: 'Developer',
            tiles: [
              _SettingsTile(
                icon: Icons.code,
                title: 'Developer',
                subtitle: 'API, plugins, analytics, logs, shaders',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DeveloperHubScreen()),
                ),
              ),
            ],
          ),
          _Section(
            title: 'About',
            tiles: [
              _SettingsTile(
                icon: Icons.storage_outlined,
                title: 'Storage',
                subtitle: 'Cache usage, temp files, incognito',
                onTap: () => context.push('/home/settings/storage'),
              ),
              _SettingsTile(
                icon: Icons.info_outline,
                title: 'About Hikmah Player',
                subtitle: 'v1.0.0',
                onTap: () => context.push('/home/settings/about'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.tiles});

  final String title;
  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
        ...tiles,
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
