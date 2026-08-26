import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../core/services/library_service.dart';
import '../../../../core/theme/app_colors.dart';

/// Modern animated scanning screen that auto-discovers media files.
///
/// Shows real-time progress of folder scanning with animated file
/// type counters and a shimmering progress bar.
class ScanningScreen extends StatefulWidget {
  const ScanningScreen({super.key});

  @override
  State<ScanningScreen> createState() => _ScanningScreenState();
}

class _ScanningScreenState extends State<ScanningScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  LibraryService? _library;
  bool _scanning = false;
  bool _done = false;
  int _videoCount = 0;
  int _audioCount = 0;
  int _imageCount = 0;
  int _totalFiles = 0;
  String _currentFolder = '';
  String _statusText = 'Preparing…';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Start scanning after first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScan());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    _library = AppScope.of(context).library;
    setState(() {
      _scanning = true;
      _statusText = 'Scanning folders…';
    });

    // Listen to library changes to update counts.
    void onLibraryChanged() => _updateCounts();
    _library!.addListener(onLibraryChanged);

    // Add common media directories and scan.
    await _addDefaultFolders();
    await _library!.scanAll();

    _updateCounts();
    _library!.removeListener(onLibraryChanged);

    setState(() {
      _scanning = false;
      _done = true;
      _statusText = 'Scan complete!';
    });

    // Auto-advance after a brief pause.
    Timer(const Duration(milliseconds: 1500), () {
      if (mounted) _finish();
    });
  }

  void _finish() {
    AppScope.of(context).prefs.onboardingCompleted = true;
    context.go('/home/videos');
  }

  Future<void> _addDefaultFolders() async {
    // The library service handles folder registration.
    // In a real app we'd use path_provider to get common directories.
    setState(() => _currentFolder = 'Internal storage');
  }

  void _updateCounts() {
    if (_library == null) return;
    final items = _library!.items;
    var videos = 0;
    var audio = 0;
    var images = 0;
    for (final item in items) {
      switch (item.media.type.name) {
        case 'video':
          videos++;
          break;
        case 'audio':
          audio++;
          break;
        case 'image':
          images++;
          break;
      }
    }
    setState(() {
      _videoCount = videos;
      _audioCount = audio;
      _imageCount = images;
      _totalFiles = items.length;
    });
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

              // Animated scanning icon
              _ScanningAnimation(
                controller: _pulseController,
                scanning: _scanning,
              ).animate().fadeIn(duration: 600.ms),

              const SizedBox(height: 32),

              // Title
              Text(
                _done ? 'All Done!' : 'Discovering Media',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

              const SizedBox(height: 8),

              // Status text
              Text(
                _statusText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

              if (_currentFolder.isNotEmpty && _scanning) ...[
                const SizedBox(height: 8),
                Text(
                  _currentFolder,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.primarySeed.withValues(alpha: 0.7),
                    fontFamily: 'monospace',
                  ),
                ),
              ],

              const SizedBox(height: 40),

              // File type counters
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _Counter(
                      icon: Icons.videocam,
                      count: _videoCount,
                      label: 'Videos',
                      color: Colors.blue,
                      delay: 400,
                    ),
                    _Counter(
                      icon: Icons.music_note,
                      count: _audioCount,
                      label: 'Audio',
                      color: Colors.purple,
                      delay: 500,
                    ),
                    _Counter(
                      icon: Icons.photo,
                      count: _imageCount,
                      label: 'Images',
                      color: Colors.teal,
                      delay: 600,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _done ? 1.0 : null,
                        minHeight: 6,
                        backgroundColor: Colors.white.withValues(alpha: 0.06),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _done ? Colors.green : AppColors.primarySeed,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _totalFiles > 0 ? '$_totalFiles files found' : '',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 700.ms, duration: 500.ms),

              const Spacer(flex: 2),

              // Continue button (shown when done)
              if (_done)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _finish,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primarySeed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Start Exploring',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 500.ms)
                      .slideY(begin: 0.2),
                ),

              if (!_done)
                TextButton(
                  onPressed: _finish,
                  child: Text(
                    'Skip for now',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ).animate().fadeIn(delay: 1000.ms, duration: 400.ms),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanningAnimation extends StatelessWidget {
  const _ScanningAnimation({
    required this.controller,
    required this.scanning,
  });

  final AnimationController controller;
  final bool scanning;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final v = controller.value;
        return Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                (scanning ? AppColors.primarySeed : Colors.green)
                    .withValues(alpha: 0.15 + (v * 0.1)),
                (scanning ? AppColors.primarySeed : Colors.green)
                    .withValues(alpha: 0.0),
              ],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Rotating outer ring (only when scanning)
              if (scanning)
                Transform.rotate(
                  angle: v * 6.28,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primarySeed.withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              // Scanning radar sweep
              if (scanning)
                Transform.rotate(
                  angle: v * 6.28,
                  child: Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 140,
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primarySeed.withValues(alpha: 0.6),
                            AppColors.primarySeed.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              // Center icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scanning ? AppColors.primarySeed : Colors.green,
                      (scanning ? AppColors.primarySeed : Colors.green)
                          .withValues(alpha: 0.7),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (scanning ? AppColors.primarySeed : Colors.green)
                          .withValues(alpha: 0.4),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  scanning ? Icons.search : Icons.check_circle,
                  size: 40,
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

class _Counter extends StatelessWidget {
  const _Counter({
    required this.icon,
    required this.count,
    required this.label,
    required this.color,
    this.delay = 0,
  });

  final IconData icon;
  final int count;
  final String label;
  final Color color;
  final int delay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          '$count',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay), duration: 400.ms)
        .slideY(begin: 0.3, duration: 400.ms, delay: Duration(milliseconds: delay));
  }
}
