import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/media_scanner.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  static const _pages = ['Welcome', 'Permissions', 'Theme', 'Ready'];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _pages.length - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    AppScope.of(context).prefs.onboardingCompleted = true;
    if (mounted) context.go('/scanning');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_pages[_page]} · ${_page + 1}/${_pages.length}'),
        actions: [TextButton(onPressed: _finish, child: const Text('Skip'))],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _controller,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _page = i),
              children: const [
                _WelcomePage(),
                _PermissionsPage(),
                _ThemePage(),
                _ReadyPage(),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_page > 0)
                    TextButton(
                      onPressed: () => _controller.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic),
                      child: const Text('Back'),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _next,
                    child: Text(_page == _pages.length - 1 ? 'Get Started' : 'Continue'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 112,
            height: 112,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primarySeed, AppColors.primaryDark],
              ),
            ),
            child: const Icon(Icons.play_arrow_rounded, size: 64, color: Colors.white),
          ),
          const SizedBox(height: 32),
          Text('Hikmah Player', style: theme.textTheme.headlineLarge),
          const SizedBox(height: 8),
          Text(
            '"Play with Wisdom"',
            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 24),
          Text(
            'A mindful media player for your videos and music — built for focus, not distraction.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _PermissionsPage extends StatefulWidget {
  const _PermissionsPage();

  @override
  State<_PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends State<_PermissionsPage> {
  bool _granted = false;
  bool _requesting = false;

  Future<void> _request() async {
    setState(() => _requesting = true);

    final sdkInt = await MediaScanner.sdkInt();
    final results = await [
      if (Platform.isAndroid && sdkInt < 33) Permission.storage,
      if (Platform.isAndroid && sdkInt >= 33) ...[Permission.videos, Permission.audio, Permission.photos],
      if (Platform.isAndroid && sdkInt >= 30) Permission.manageExternalStorage,
      if (!Platform.isAndroid) Permission.storage,
    ].request();

    if (!mounted) return;
    setState(() {
      if (Platform.isAndroid && sdkInt < 33) {
        _granted = results[Permission.storage]?.isGranted ?? false;
      } else if (Platform.isAndroid && sdkInt >= 33) {
        // "All files access" (SD / USB / OTG) is optional — the scan falls
        // back to MediaStore without it — so it never blocks the flow.
        _granted = (results[Permission.videos]?.isGranted ?? false) && (results[Permission.audio]?.isGranted ?? false);
      } else {
        _granted = results[Permission.storage]?.isGranted ?? false;
      }
      _requesting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.folder_shared_outlined, size: 88, color: theme.colorScheme.primary),
          const SizedBox(height: 24),
          Text('Access your media', textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(
            'Hikmah needs read access to discover your video and audio library. Nothing is uploaded — everything stays on device.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 32),
          if (!_granted)
            FilledButton.icon(
              onPressed: _requesting ? null : _request,
              icon: _requesting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.lock_open),
              label: const Text('Grant Access'),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Icon(Icons.check_circle, color: theme.colorScheme.primary), const SizedBox(width: 8), const Text('Access granted')],
            ),
        ],
      ),
    );
  }
}

class _ThemePage extends StatelessWidget {
  const _ThemePage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = AppScope.of(context).theme;
    final current = controller.themeMode;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.palette_outlined, size: 88, color: theme.colorScheme.primary),
          const SizedBox(height: 24),
          Text('Pick your look', textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('You can change this anytime in Settings.', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 24),
          _ThemeOptionCard(icon: Icons.light_mode_outlined, title: 'Light', selected: current == ThemeMode.light, onTap: () => controller.setThemeMode(ThemeMode.light)),
          const SizedBox(height: 8),
          _ThemeOptionCard(icon: Icons.dark_mode_outlined, title: 'Dark', selected: current == ThemeMode.dark, onTap: () => controller.setThemeMode(ThemeMode.dark)),
          const SizedBox(height: 8),
          _ThemeOptionCard(icon: Icons.settings_suggest_outlined, title: 'System', subtitle: 'Follows your device setting', selected: current == ThemeMode.system, onTap: () => controller.setThemeMode(ThemeMode.system)),
        ],
      ),
    );
  }
}

class _ThemeOptionCard extends StatelessWidget {
  const _ThemeOptionCard({required this.icon, required this.title, required this.selected, required this.onTap, this.subtitle});

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: selected ? theme.colorScheme.primary : theme.colorScheme.outline),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: selected ? Icon(Icons.radio_button_checked, color: theme.colorScheme.primary) : const Icon(Icons.radio_button_off),
      ),
    );
  }
}

class _ReadyPage extends StatelessWidget {
  const _ReadyPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_outlined, size: 88, color: theme.colorScheme.primary),
          const SizedBox(height: 24),
          Text("You're all set!", style: theme.textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(
            'Next, Hikmah will scan your device to build your media library. This happens once and can be redone anytime.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
