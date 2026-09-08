import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/di/app_scope.dart';
import '../../domain/models/media_item.dart';
import '../../domain/models/playback_queue.dart';
import '../providers/playback_provider.dart';
import '../widgets/audio_visualizer.dart';
import '../widgets/controls_overlay.dart';
import '../widgets/gesture_detector.dart';
import '../widgets/pip_player.dart';
import '../widgets/video_output.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, this.queue});

  final PlaybackQueue? queue;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  PlaybackController? _controller;
  bool _opened = false;
  bool _pip = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller == null) {
      final services = AppScope.of(context);
      _controller = PlaybackController(
        services.playback,
        services.subtitle,
        repository: services.playerData,
        history: services.history,
        prefs: services.prefs,
      );
    }
    final queue = widget.queue;
    if (queue != null && !_opened && _controller != null) {
      _opened = true;
      _controller!.openQueue(queue);
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) return const SizedBox.shrink();
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildBackdrop(controller),
          PlayerGestureDetector(
            controller: controller,
            playback: controller.playback,
            child: const SizedBox.expand(),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(context, controller),
                const Spacer(),
                _buildGestureOverlay(controller),
                const Spacer(),
                SubtitleSpace(controller: controller),
                _buildControls(controller),
              ],
            ),
          ),
          if (_pip)
            PipPlayer(
              playback: controller.playback,
              onClose: () => setState(() => _pip = false),
            ),
        ],
      ),
    );
  }

  Widget _buildBackdrop(PlaybackController controller) {
    final playback = controller.playback;
    return ValueListenableBuilder<String?>(
      valueListenable: playback.currentMediaId,
      builder: (context, _, _) {
        final hasVideo = playback.hasVideo;
        final item = playback.currentItem;
        if (hasVideo) return VideoOutput(playback: playback);
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0B0B0B), Color(0xFF121212), Color(0xFF0B0B0B)],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.5,
                  child: AudioVisualizer(playback: playback),
                ),
              ),
              if (item != null)
                Center(
                  child: item.artworkUri == null
                      ? Icon(Icons.music_note_rounded, size: 96, color: Colors.white.withValues(alpha: 0.15))
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            item.artworkUri!,
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Icon(Icons.music_note_rounded, size: 96, color: Colors.white.withValues(alpha: 0.15)),
                          ),
                        ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context, PlaybackController controller) {
    final playback = controller.playback;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final item = playback.currentItem;
        return AnimatedOpacity(
          opacity: controller.controlsVisible ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.maybePop(context),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item?.title ?? 'No media',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                    ),
                    if (item != null && item.type == MediaType.audio)
                      Text(
                        [item.artist, item.album].whereType<String>().join(' — '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Picture in picture',
                icon: Icon(_pip ? Icons.picture_in_picture_alt_rounded : Icons.picture_in_picture_rounded, color: Colors.white),
                onPressed: () => setState(() => _pip = !_pip),
              ),
              IconButton(
                tooltip: 'Close player',
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.maybePop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGestureOverlay(PlaybackController controller) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (!controller.gestureActive) return const SizedBox.shrink();
        final icon = controller.gestureLabel.contains('right')
            ? Icons.volume_up
            : controller.gestureLabel.contains('Brightness')
                ? Icons.brightness_6
                : Icons.schedule;
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 40),
              const SizedBox(height: 8),
              Text(
                '${controller.gestureLabel}  ${(controller.gestureValue * 100).round()}%',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControls(PlaybackController controller) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return AnimatedOpacity(
          opacity: controller.controlsVisible ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)],
              ),
            ),
            padding: const EdgeInsets.only(top: 24, bottom: 8),
            child: ControlsOverlay(
              controller: controller,
              playback: controller.playback,
            ),
          ),
        );
      },
    );
  }
}

class SubtitleSpace extends StatelessWidget {
  const SubtitleSpace({super.key, required this.controller});

  final PlaybackController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<String>>(
      valueListenable: controller.playback.currentSubtitles,
      builder: (context, lines, _) {
        if (lines.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          child: Text(
            lines.join('\n'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  shadows: const [Shadow(blurRadius: 6, color: Colors.black)],
                ),
          ),
        );
      },
    );
  }
}
