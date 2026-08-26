import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../../../core/di/app_scope.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/enhanced_player_controls.dart';
import '../widgets/gesture_overlay.dart';

class EnhancedVideoPlayerScreen extends ConsumerStatefulWidget {
  final String mediaId;

  const EnhancedVideoPlayerScreen({super.key, required this.mediaId});

  @override
  ConsumerState<EnhancedVideoPlayerScreen> createState() =>
      _EnhancedVideoPlayerScreenState();
}

class _EnhancedVideoPlayerScreenState extends ConsumerState<EnhancedVideoPlayerScreen> {
  late final VideoController _videoController;
  bool _controlsVisible = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();

    // Initialize video controller
    final playbackService = AppScope.of(context).playback;
    _videoController = VideoController(playbackService.engine);

    _initScreen();
  }

  Future<void> _initScreen() async {
    // Enter landscape
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Hide system UI
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _startHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();

    // Restore system UI
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  void _toggleControls() {
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) _startHideTimer();
  }

  void _showControlsAndReset() {
    if (!_controlsVisible) setState(() => _controlsVisible = true);
    _startHideTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.playerBackground,
      body: Stack(
        children: [
          // ─── Video Surface ───
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleControls,
              child: Video(
                controller: _videoController,
                controls: NoVideoControls,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // ─── Gesture Overlay (brightness/volume/seek) ───
          Positioned.fill(
            child: GestureOverlay(
              onInteraction: _showControlsAndReset,
            ),
          ),

          // ─── Player Controls (overlay) ───
          AnimatedOpacity(
            opacity: _controlsVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: !_controlsVisible,
              child: EnhancedPlayerControls(
                onInteraction: _showControlsAndReset,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
