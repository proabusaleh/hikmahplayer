import 'dart:async';

import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../core/di/app_services.dart';
import '../../../../core/services/playback_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/playback_settings.dart';
import '../../domain/models/playback_state.dart';
import '../providers/player_state_provider.dart';
import '../widgets/enhanced_player_controls.dart';
import '../widgets/gesture_overlay.dart';
import '../widgets/subtitle_renderer.dart';

/// Full-screen, landscape-first video player with gesture-driven controls.
///
/// Hosts the [EnhancedPlayerControls] overlay and [GestureOverlay] on top of a
/// [Video] surface. Also owns transient player concerns:
/// * screen lock (tap-to-unlock)
/// * orientation lock / auto-orientation from the video aspect ratio
/// * pinch-zoom + pan transform
/// * seek thumbnail preview (latest rendered frame after scrubbing)
/// * restoring the remembered playback speed for the opened video
class EnhancedVideoPlayerScreen extends ConsumerStatefulWidget {
  final String mediaId;

  const EnhancedVideoPlayerScreen({super.key, required this.mediaId});

  @override
  ConsumerState<EnhancedVideoPlayerScreen> createState() =>
      _EnhancedVideoPlayerScreenState();
}

class _EnhancedVideoPlayerScreenState
    extends ConsumerState<EnhancedVideoPlayerScreen> {
  late final VideoController _videoController;
  final TransformationController _transformController =
      TransformationController();

  bool _controlsVisible = true;
  Timer? _hideTimer;

  bool _locked = false;
  bool _autoNext = false;
  VideoOrientation _orientation = VideoOrientation.auto;

  Uint8List? _previewThumb;
  Timer? _thumbTimer;
  AppServices? _services;
  PlaybackService? _playback;

  @override
  void initState() {
    super.initState();
    final services = AppScope.of(context);
    _services = services;
    _playback = services.playback;
    _videoController = VideoController(services.playback.engine);
    _orientation =
        VideoOrientation.fromName(services.prefs.videoOrientation);

    services.playback.videoWidth.addListener(_onVideoSizeChanged);
    services.playback.videoHeight.addListener(_onVideoSizeChanged);
    services.playback.isCompleted.addListener(_onCompleted);

    _initScreen();
  }

  Future<void> _initScreen() async {
    await _applyOrientation();

    // Hide system UI and keep the screen awake during playback.
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await WakelockPlus.enable();

    await _restoreRememberedSpeed();
    _startHideTimer();
  }

  Future<void> _restoreRememberedSpeed() async {
    final services = AppScope.of(context);
    if (!services.prefs.rememberVideoSpeed) return;
    final mediaId = services.playback.currentMediaId.value;
    if (mediaId == null) return;
    final saved = services.prefs.videoSpeed(mediaId);
    if (saved.compareTo(1.0) != 0) {
      await ref.read(playerStateProvider.notifier).setSpeed(saved);
    }
  }

  void _onVideoSizeChanged() {
    if (_orientation != VideoOrientation.auto) return;
    final services = AppScope.of(context);
    final width = services.playback.videoWidth.value ?? 0;
    final height = services.playback.videoHeight.value ?? 0;
    if (width <= 0 || height <= 0) return;
    SystemChrome.setPreferredOrientations(
      width >= height
          ? _landscapeOrientations
          : _portraitOrientations,
    );
  }

  static const List<DeviceOrientation> _landscapeOrientations = [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ];
  static const List<DeviceOrientation> _portraitOrientations = [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ];

  Future<void> _applyOrientation() async {
    final services = AppScope.of(context);
    services.prefs.videoOrientation = _orientation.name;
    switch (_orientation) {
      case VideoOrientation.auto:
        _onVideoSizeChanged();
      case VideoOrientation.landscape:
        await SystemChrome.setPreferredOrientations(_landscapeOrientations);
      case VideoOrientation.portrait:
        await SystemChrome.setPreferredOrientations(_portraitOrientations);
    }
  }

  void _setOrientation(VideoOrientation orientation) {
    if (orientation == _orientation) return;
    setState(() => _orientation = orientation);
    _applyOrientation();
  }

  // ─── Controls visibility ───

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

  // ─── Screen lock ───

  void _lock() {
    _hideTimer?.cancel();
    setState(() {
      _locked = true;
      _controlsVisible = false;
    });
  }

  void _unlock() {
    setState(() => _locked = false);
    _showControlsAndReset();
  }

  // ─── Auto-next on completion ───

  void _toggleAutoNext(bool enabled) {
    setState(() => _autoNext = enabled);
  }

  void _onCompleted() {
    final playback = _playback;
    if (playback == null || !_autoNext) return;
    if (!playback.isCompleted.value) return;
    final items = playback.queueItems;
    final index = playback.currentIndex.value;
    final repeats =
        playback.repeatMode.value == RepeatMode.all;
    if (index < items.length - 1 || repeats) {
      playback.next();
    }
  }

  // ─── Seek thumbnail preview ───

  Future<void> _showPreviewThumbnail(Duration position) async {
    final services = AppScope.of(context);
    Uint8List? thumb;
    try {
      thumb = await services.playback.captureFrame();
    } catch (_) {
      thumb = null;
    }
    if (!mounted) return;

    setState(() => _previewThumb = thumb);
    _thumbTimer?.cancel();
    if (thumb != null) {
      _thumbTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _previewThumb = null);
      });
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _thumbTimer?.cancel();

    final services = _services;
    if (services != null) {
      services.playback.videoWidth.removeListener(_onVideoSizeChanged);
      services.playback.videoHeight.removeListener(_onVideoSizeChanged);
      services.playback.isCompleted.removeListener(_onCompleted);
    }
    _transformController.dispose();

    unawaited(
      SystemChrome.setPreferredOrientations(_portraitOrientations),
    );
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    unawaited(WakelockPlus.disable());

    super.dispose();
  }

  BoxFit _boxFitFor(VideoFit fit) => switch (fit) {
        VideoFit.contain => BoxFit.contain,
        VideoFit.cover => BoxFit.cover,
        VideoFit.fill => BoxFit.fill,
        VideoFit.natural => BoxFit.none,
      };

  @override
  Widget build(BuildContext context) {
    final videoFit = ref.watch(playerStateProvider.select((s) => s.videoFit));

    return Scaffold(
      backgroundColor: AppColors.playerBackground,
      body: Stack(
        children: [
          // ─── Video Surface (fitted + pinch zoom/pan) ───
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleControls,
              child: Transform(
                alignment: Alignment.center,
                transform: _transformController.value,
                child: Video(
                  controller: _videoController,
                  controls: NoVideoControls,
                  fit: _boxFitFor(videoFit),
                ),
              ),
            ),
          ),

          // ─── Subtitle Overlay ───
          Positioned.fill(
            child: IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 220),
                child: ValueListenableBuilder<List<String>>(
                  valueListenable: _playback!.currentSubtitles,
                  builder: (context, lines, _) =>
                      SubtitleRenderer(lines: lines),
                ),
              ),
            ),
          ),

          // ─── Gesture Overlay (brightness/volume/seek/boost/zoom) ───
          Positioned.fill(
            child: GestureOverlay(
              onInteraction: _showControlsAndReset,
              locked: _locked,
              transformController: _transformController,
              onSeekEnd: _showPreviewThumbnail,
            ),
          ),

          // ─── Player Controls (overlay) ───
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: _controlsVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !_controlsVisible,
                child: EnhancedPlayerControls(
                  onInteraction: _showControlsAndReset,
                  locked: _locked,
                  onLock: _lock,
                  orientation: _orientation,
                  onSetOrientation: _setOrientation,
                  onResetZoom: () => _transformController.value =
                      Matrix4.identity(),
                  onSeekEnd: _showPreviewThumbnail,
                  autoNext: _autoNext,
                  onAutoNextChanged: _toggleAutoNext,
                ),
              ),
            ),
          ),

          // ─── Seek thumbnail preview ───
          if (_previewThumb != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 180,
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.memory(
                      _previewThumb!,
                      width: 240,
                      height: 135,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),

          // ─── Screen lock overlay ───
          if (_locked)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _unlock,
                child: Container(
                  color: Colors.black54,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        color: Colors.white,
                        size: 56,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Locked · tap to unlock',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}