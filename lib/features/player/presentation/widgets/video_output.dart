import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../../core/services/playback_service.dart';
import 'subtitle_renderer.dart';

/// Renders the video texture for the shared [PlaybackService] engine with the
/// accessibility-styled subtitle overlay on top.
class VideoOutput extends StatefulWidget {
  const VideoOutput({super.key, required this.playback});

  final PlaybackService playback;

  @override
  State<VideoOutput> createState() => _VideoOutputState();
}

class _VideoOutputState extends State<VideoOutput> {
  late final VideoController _videoController =
      VideoController(widget.playback.engine);

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: Colors.black,
          child: Video(
            controller: _videoController,
            controls: NoVideoControls,
            fit: BoxFit.contain,
          ),
        ),
        // Subtitle overlay, styled by the accessibility layer.
        ValueListenableBuilder<List<String>>(
          valueListenable: widget.playback.currentSubtitles,
          builder: (context, lines, _) {
            return IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 96),
                child: SubtitleRenderer(lines: lines),
              ),
            );
          },
        ),
      ],
    );
  }
}
