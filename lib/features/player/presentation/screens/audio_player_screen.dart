import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../core/storage/repositories/media_repository.dart';

class AudioPlayerScreen extends StatelessWidget {
  const AudioPlayerScreen({super.key, required this.mediaId});

  final String mediaId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Now Playing')),
      body: FutureBuilder<MediaItem?>(
        future: AppScope.of(context).media.byId(mediaId),
        builder: (context, snapshot) {
          final item = snapshot.data;
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.album,
                      size: 96, color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 24),
                Text(item?.title ?? item?.fileName ?? mediaId,
                    style: theme.textTheme.titleLarge),
                Text(item?.artist ?? 'Unknown artist',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    )),
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Playback controls land in the audio player phase.',
                    textAlign: TextAlign.center,
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
