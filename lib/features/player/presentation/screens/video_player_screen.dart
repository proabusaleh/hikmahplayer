import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../core/storage/repositories/media_repository.dart';

class VideoPlayerScreen extends StatelessWidget {
  const VideoPlayerScreen({super.key, required this.mediaId});

  final String mediaId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<MediaItem?>(
        future: AppScope.of(context).media.byId(mediaId),
        builder: (context, snapshot) {
          final item = snapshot.data;
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.play_circle_fill,
                  size: 96,
                  color: Colors.white24,
                ),
                const SizedBox(height: 16),
                Text(
                  item?.title ?? item?.fileName ?? mediaId,
                  style: const TextStyle(color: Colors.white70),
                ),
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Playback engine wiring lands in the player phase.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
