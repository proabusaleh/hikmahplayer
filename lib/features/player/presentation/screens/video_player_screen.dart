import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../core/storage/repositories/media_repository.dart';
import '../../../../presentation/providers/player_provider.dart'
    show playerMediaFromRow;
import '../../domain/models/playback_queue.dart';
import 'player_screen.dart';

/// Full-screen video player for a single item.
///
/// Resolves the requested [mediaId] from the library and hands it to the
/// full-featured [PlayerScreen] as a single-item queue, so video playback gets
/// the same engine, gestures, controls, subtitles and PiP as everywhere else.
class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key, required this.mediaId});

  final String mediaId;

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  Future<MediaItem?> get _media =>
      AppScope.of(context).media.byId(widget.mediaId);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MediaItem?>(
      future: _media,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final item = snapshot.data;
        if (item == null) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: const Center(
              child: Text('Media not found', style: TextStyle(color: Colors.white70)),
            ),
          );
        }
        final queue = PlaybackQueue.single(playerMediaFromRow(item));
        return PlayerScreen(queue: queue);
      },
    );
  }
}
