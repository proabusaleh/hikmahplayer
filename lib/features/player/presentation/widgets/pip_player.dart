import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../../core/services/playback_service.dart';

/// Floating picture-in-picture preview shown inside the player.
///
/// A draggable mini window that keeps rendering the current video so the user
/// can keep watching while interacting with other player UI. Best-effort
/// approach that works on every Flutter platform.
class PipPlayer extends StatefulWidget {
  const PipPlayer({super.key, required this.playback, this.onClose});

  final PlaybackService playback;
  final VoidCallback? onClose;

  @override
  State<PipPlayer> createState() => _PipPlayerState();
}

class _PipPlayerState extends State<PipPlayer> {
  static const double _width = 180;
  static const double _height = 112;

  Offset _offset = const Offset(24, 120);
  late final VideoController _videoController =
      VideoController(widget.playback.engine);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          left: _offset.dx,
          top: _offset.dy,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: (details) {
              setState(() {
                _offset = Offset(
                  (_offset.dx + details.delta.dx)
                      .clamp(0, MediaQuery.of(context).size.width - _width),
                  (_offset.dy + details.delta.dy)
                      .clamp(0, MediaQuery.of(context).size.height - _height),
                );
              });
            },
            child: Container(
              width: _width,
              height: _height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
                boxShadow: const [
                  BoxShadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 4)),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
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
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton.filled(
                      style: IconButton.styleFrom(
                        minimumSize: const Size(28, 28),
                        padding: EdgeInsets.zero,
                        backgroundColor: Colors.black54,
                      ),
                      iconSize: 16,
                      icon: const Icon(Icons.close),
                      onPressed: widget.onClose,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
