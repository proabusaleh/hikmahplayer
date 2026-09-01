import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/media_scanner.dart';

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
    final permissionsToRequest = await _mediaPermissionsToRequest();
    final granted = <Permission>{};

    for (final permission in permissionsToRequest) {
      if ((await permission.status).isGranted) {
        granted.add(permission);
      }
    }

    final result = _interpretGranted(permissionsToRequest, granted);
    setState(() {
      _statuses['Storage'] = result.storage;
      _statuses['Photos'] = result.photos;
      _statuses['Videos'] = result.videos;
      _statuses['Audio'] = result.audio;
      _allGranted = result.allGranted;
    });

    if (_allGranted) {
      widget.onPermissionsGranted?.call();
    }
  }

  /// Maps the set of granted [permissions] to the four on-screen states.
  ///
  /// On Android 12 and below a single [Permission.storage] grant covers all
  /// media, so it counts as granting photos, videos and audio together.
  ({bool storage, bool photos, bool videos, bool audio, bool allGranted})
      _interpretGranted(List<Permission> requested, Set<Permission> granted) {
    final storage = granted.contains(Permission.storage);
    final photos = granted.contains(Permission.photos);
    final videos = granted.contains(Permission.videos);
    final audio = granted.contains(Permission.audio);

    final storageCoversAll = storage && !requested.contains(Permission.photos);
    final photosGranted = photos || storageCoversAll;
    final videosGranted = videos || storageCoversAll;
    final audioGranted = audio || storageCoversAll;

    return (
      storage: storage || photos || videos || audio,
      photos: photosGranted,
      videos: videosGranted,
      audio: audioGranted,
      allGranted: photosGranted && videosGranted && audioGranted,
    );
  }

  Future<void> _requestPermissions() async {
    setState(() => _requesting = true);
    try {
      // Request each permission individually. Batching the granular
      // READ_MEDIA_* permissions into a single request can leave the native
      // handler's bookkeeping in a state where the result callback never
      // fires, which would leave this screen stuck on its loading spinner.
      // A separate request per permission is also the reliable way to get a
      // dialog on Android 13+ for every media type.
      final permissionsToRequest = await _mediaPermissionsToRequest();
      final granted = <Permission>{};

      for (final permission in permissionsToRequest) {
        // Guard against a native request ever hanging (e.g. the OS killing
        // the activity mid-dialog). Without this the spinner would spin
        // forever even though the dialog was actually granted.
        final status = await permission
            .request()
            .timeout(const Duration(seconds: 10));
        if (status.isGranted || status.isLimited) {
          granted.add(permission);
        }
      }

      final result = _interpretGranted(permissionsToRequest, granted);
      setState(() {
        _statuses['Storage'] = result.storage;
        _statuses['Photos'] = result.photos;
        _statuses['Videos'] = result.videos;
        _statuses['Audio'] = result.audio;
        _allGranted = result.allGranted;
      });

      if (_allGranted) {
        widget.onPermissionsGranted?.call();
      }
    } finally {
      // Always clear the loading state so the button is usable again, even
      // if a permission request threw or timed out.
      if (mounted) setState(() => _requesting = false);
    }
  }

  /// The permissions to request for this platform, in a stable order.
  ///
  /// On Android 13+ (API 33) `Permission.storage` is never grantable, so the
  /// granular READ_MEDIA_* permissions are requested instead. On Android 12
  /// and below those granular permissions don't exist, so we fall back to
  /// `Permission.storage`.
  Future<List<Permission>> _mediaPermissionsToRequest() async {
    if (!Platform.isAndroid) {
      return [Permission.storage, Permission.photos, Permission.videos, Permission.audio];
    }
    final isAndroid13Plus = await MediaScanner.sdkInt() >= 33;
    if (isAndroid13Plus) {
      return [Permission.photos, Permission.videos, Permission.audio];
    }
    return [Permission.storage];
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
              AppColors.surfaceDark,
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
                      backgroundColor: AppColors.primarySeed,
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
                AppColors.primarySeed.withValues(alpha: 0.2 + (v * 0.1)),
                AppColors.primarySeed.withValues(alpha: 0.0),
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
                      color: AppColors.primarySeed.withValues(alpha: 0.3),
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
                      AppColors.primarySeed,
                      AppColors.primarySeed.withValues(alpha: 0.7),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primarySeed.withValues(alpha: 0.4),
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
