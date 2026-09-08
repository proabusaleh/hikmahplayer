import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/route_names.dart';
import '../../../../presentation/providers/scanner_provider.dart';
import '../../../../presentation/providers/theme_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prefs = AppScope.of(context).prefs;
    final themeState = ref.watch(themeProvider);
    final scanState = ref.watch(scannerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // ─── Appearance ───
          _Section(
            title: 'Appearance',
            children: [
              ListTile(
                leading: Icon(Icons.palette_outlined,
                    color: theme.colorScheme.onSurfaceVariant),
                title: const Text('Theme'),
                subtitle: Text(_themeModeLabel(themeState.mode)),
                trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                onTap: () => context.push(RouteNames.settingsTheme),
              ),
              SwitchListTile(
                secondary: Icon(Icons.contrast,
                    color: theme.colorScheme.onSurfaceVariant),
                title: const Text('Pure black mode'),
                subtitle: const Text('AMOLED-friendly dark surfaces'),
                value: themeState.pureBlack,
                onChanged: (_) =>
                    ref.read(themeProvider.notifier).togglePureBlack(),
              ),
              ListTile(
                leading: Icon(Icons.color_lens_outlined,
                    color: theme.colorScheme.onSurfaceVariant),
                title: const Text('Accent color'),
                subtitle: Text(_currentSeedLabel(themeState.seedColor)),
                trailing: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: themeState.seedColor,
                    shape: BoxShape.circle,
                  ),
                ),
                onTap: () => context.push(RouteNames.settingsTheme),
              ),
            ],
          ),

          // ─── Playback ───
          _Section(
            title: 'Playback',
            children: [
              SwitchListTile(
                secondary: Icon(Icons.play_circle_outline,
                    color: theme.colorScheme.onSurfaceVariant),
                title: const Text('Resume playback'),
                subtitle: const Text('Continue where you left off'),
                value: prefs.resumePlayback,
                onChanged: (v) =>
                    setState(() => prefs.resumePlayback = v),
              ),
              SwitchListTile(
                secondary: Icon(Icons.queue_play_next,
                    color: theme.colorScheme.onSurfaceVariant),
                title: const Text('Auto-play next'),
                subtitle: const Text('Advance the queue automatically'),
                value: prefs.autoPlay,
                onChanged: (v) =>
                    setState(() => prefs.autoPlay = v),
              ),
              ListTile(
                leading: Icon(Icons.speed,
                    color: theme.colorScheme.onSurfaceVariant),
                title: const Text('Default speed'),
                trailing: DropdownButton<double>(
                  value: prefs.defaultPlaybackSpeed,
                  items: const [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
                      .map((s) =>
                          DropdownMenuItem(value: s, child: Text('${s}x')))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => prefs.defaultPlaybackSpeed = v);
                    }
                  },
                ),
              ),
              ListTile(
                leading: Icon(Icons.settings_outlined,
                    color: theme.colorScheme.onSurfaceVariant),
                title: const Text('More playback settings'),
                subtitle: const Text('Video fit, loop mode, volume'),
                trailing:
                    const Icon(Icons.chevron_right_rounded, size: 18),
                onTap: () => context.push(RouteNames.settingsPlayback),
              ),
            ],
          ),

          // ─── Library ───
          _Section(
            title: 'Library',
            children: [
              ListTile(
                leading: Icon(Icons.refresh,
                    color: theme.colorScheme.onSurfaceVariant),
                title: const Text('Rescan media'),
                subtitle: Text(_scanLabel(scanState)),
                onTap: scanState is ScanInProgress
                    ? null
                    : () => ref
                        .read(scannerProvider.notifier)
                        .startScan(),
              ),
            ],
          ),

          // ─── Privacy ───
          _Section(
            title: 'Privacy',
            children: [
              SwitchListTile(
                secondary: Icon(Icons.visibility_off_outlined,
                    color: theme.colorScheme.onSurfaceVariant),
                title: const Text('Incognito mode'),
                subtitle: const Text('Pause history recording'),
                value: prefs.incognitoMode,
                onChanged: (v) =>
                    setState(() => prefs.incognitoMode = v),
              ),
            ],
          ),

          // ─── Insights ───
          _Section(
            title: 'Insights',
            children: [
              ListTile(
                leading: Icon(Icons.insights_outlined,
                    color: theme.colorScheme.onSurfaceVariant),
                title: const Text('Statistics & analytics'),
                subtitle: const Text('Watch time, completion, top media'),
                trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                onTap: () => context.push(RouteNames.settingsStatistics),
              ),
              ListTile(
                leading: Icon(Icons.storage_outlined,
                    color: theme.colorScheme.onSurfaceVariant),
                title: const Text('Storage manager'),
                subtitle: const Text('Largest files, duplicates, cleanup'),
                trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                onTap: () => context.push(RouteNames.settingsStorageManager),
              ),
            ],
          ),

          // ─── About ───
          _Section(
            title: 'About',
            children: [
              ListTile(
                leading: Icon(Icons.storage_outlined,
                    color: theme.colorScheme.onSurfaceVariant),
                title: const Text('Storage'),
                subtitle: const Text('Cache usage, temp files'),
                trailing:
                    const Icon(Icons.chevron_right_rounded, size: 18),
                onTap: () => context.push(RouteNames.settingsStorage),
              ),
              ListTile(
                leading: Icon(Icons.info_outline,
                    color: theme.colorScheme.onSurfaceVariant),
                title: const Text('About Hikmah Player'),
                subtitle: FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (_, snapshot) => Text(
                    snapshot.data != null
                        ? 'v${snapshot.data!.version} '
                            '(${snapshot.data!.buildNumber})'
                        : 'Version \u2026',
                  ),
                ),
                trailing:
                    const Icon(Icons.chevron_right_rounded, size: 18),
                onTap: () => context.push(RouteNames.settingsAbout),
              ),
              ListTile(
                leading: Icon(Icons.gavel_outlined,
                    color: theme.colorScheme.onSurfaceVariant),
                title: const Text('Licenses'),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'Hikmah Player',
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  static String _themeModeLabel(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
        ThemeMode.system => 'System',
      };

  static String _currentSeedLabel(Color color) {
    for (final choice in AppColors.seedChoices) {
      if (choice.color.toARGB32() == color.toARGB32()) return choice.label;
    }
    return AppColors.seedChoices.first.label;
  }

  static String _scanLabel(ScanState state) => switch (state) {
        ScanInProgress(:final processed, :final total) =>
          'Scanning\u2026 $processed/$total',
        ScanCompleted(:final foundCount) =>
          'Last scan found $foundCount items',
        ScanError(:final message) => 'Error: $message',
        ScanIdle() => 'Scan for new media files',
      };
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}
