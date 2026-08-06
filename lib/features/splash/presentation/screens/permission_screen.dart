import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/themes/app_theme.dart';

/// Modern animated permission request screen.
///
/// Requests storage, photos, videos, and audio permissions with
/// animated illustrations and clear explanations.
class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key, this.onPermissionsGranted});

  final VoidCallback? onPermissionsGranted;

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _illustrationController;
  bool _requesting = false;
  bool _allGranted = false;
  final Map<String, bool> _statuses = {};

  @override
  void initState() {
    super.initState();
    _illustrationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _checkExistingPermissions();
  }

  @override
  void dispose() {
    _illustrationController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingPermissions() async {
    final storage = await Permission.storage.status;
    final photos = await Permission.photos.status;
    final videos = await Permission.videos.status;
    final audio = await Permission.audio.status;

    setState(() {
      _statuses['Storage'] = storage.isGranted;
      _statuses['Photos'] = photos.isGranted;
      _statuses['Videos'] = videos.isGranted;
      _statuses['Audio'] = audio.isGranted;
      _allGranted = storage.isGranted && photos.isGranted && videos.isGranted && audio.isGranted;
    });

    if (_allGranted) {
      widget.onPermissionsGranted?.call();
    }
  }

  Future<void> _requestPermissions() async {
    setState(() => _requesting = true);

    final results = await [
      Permission.storage,
      Permission.photos,
      Permission.videos,
      Permission.audio,
    ].request();

    setState(() {
      _statuses['Storage'] = results[Permission.storage]?.isGranted ?? false;
      _statuses['Photos'] = results[Permission.photos]?.isGranted ?? false;
      _statuses['Videos'] = results[Permission.videos]?.isGranted ?? false;
      _statuses['Audio'] = results[Permission.audio]?.isGranted ?? false;
      _allGranted = results.values.every((r) => r.isGranted);
      _requesting = false;
    });

    if (_allGranted) {
      widget.onPermissionsGranted?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D0F1A),
              AppTheme.scaffold,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Animated illustration
              _PermissionIllustration(controller: _illustrationController)
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .scale(begin: const Offset(0.9, 0.9), duration: 600.ms),

              const SizedBox(height: 32),

              // Title
              Text(
                'Access Your Media',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

              const SizedBox(height: 12),

              // Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Text(
                  'Hikmah needs access to your files to discover and play your video, audio, and media collection.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.6),
                    height: 1.5,
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 500.ms),

              const SizedBox(height: 32),

              // Permission status cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    _PermissionCard(
                      icon: Icons.folder,
                      title: 'Storage',
                      subtitle: 'Access media files on your device',
                      granted: _statuses['Storage'] ?? false,
                      delay: 500,
                    ),
                    const SizedBox(height: 8),
                    _PermissionCard(
                      icon: Icons.photo_library,
                      title: 'Photos & Videos',
                      subtitle: 'Discover video files and thumbnails',
                      granted: _statuses['Photos'] ?? false,
                      delay: 600,
                    ),
                    const SizedBox(height: 8),
                    _PermissionCard(
                      icon: Icons.videocam,
                      title: 'Videos',
                      subtitle: 'Play video content from your library',
                      granted: _statuses['Videos'] ?? false,
                      delay: 700,
                    ),
                    const SizedBox(height: 8),
                    _PermissionCard(
                      icon: Icons.music_note,
                      title: 'Audio',
                      subtitle: 'Play music and audio files',
                      granted: _statuses['Audio'] ?? false,
                      delay: 800,
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // Grant button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _requesting ? null : _requestPermissions,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.seed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _requesting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _allGranted ? 'Continue' : 'Grant Access',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ).animate().fadeIn(delay: 900.ms, duration: 500.ms).slideY(begin: 0.2),
              ),

              const SizedBox(height: 16),

              // Skip / info
              if (!_allGranted)
                TextButton(
                  onPressed: () => openAppSettings(),
                  child: Text(
                    'Open Settings',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ).animate().fadeIn(delay: 1100.ms, duration: 400.ms),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionIllustration extends StatelessWidget {
  const _PermissionIllustration({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final v = controller.value;
        return Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppTheme.seed.withValues(alpha: 0.2 + (v * 0.1)),
                AppTheme.seed.withValues(alpha: 0.0),
              ],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Rotating ring
              Transform.rotate(
                angle: v * 6.28,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.seed.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                ),
              ),
              // Center icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.seed,
                      AppTheme.seed.withValues(alpha: 0.7),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.seed.withValues(alpha: 0.4),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.folder_open,
                  size: 36,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.granted,
    this.delay = 0,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool granted;
  final int delay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: granted
            ? Colors.green.withValues(alpha: 0.1)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: granted
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 22,
            color: granted ? Colors.green : theme.colorScheme.outline,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: granted ? Colors.green : Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            granted ? Icons.check_circle : Icons.arrow_forward_ios,
            size: 18,
            color: granted ? Colors.green : theme.colorScheme.outline,
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay), duration: 400.ms);
  }
}
