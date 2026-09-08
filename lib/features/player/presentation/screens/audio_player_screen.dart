import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../core/storage/repositories/media_repository.dart';
import '../../../../presentation/providers/player_provider.dart'
    show playerMediaFromRow;
import '../../domain/models/playback_queue.dart';
import 'player_screen.dart';

/// Full-screen "Now Playing" for an audio item.
///
/// Resolves the requested [mediaId] from the library and hands it to the
/// full-featured [PlayerScreen] as a single-item queue, so audio playback
/// gets the same rich controls, visualizer, gestures and PiP as video.
class AudioPlayerScreen extends StatefulWidget {
  const AudioPlayerScreen({super.key, required this.mediaId});

  final String mediaId;

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  Future<MediaItem?> get _media =>
      AppScope.of(context).media.byId(widget.mediaId);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MediaItem?>(
      future: _media,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final item = snapshot.data;
        if (item == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Now Playing')),
            body: const Center(child: Text('Media not found')),
          );
        }
        final queue = PlaybackQueue.single(playerMediaFromRow(item));
        return PlayerScreen(queue: queue);
      },
    );
  }
}
