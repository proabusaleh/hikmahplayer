import 'package:flutter/material.dart';

import '../../../../core/di/app_services.dart';
import '../../../../core/di/app_scope.dart';
import '../../../../core/storage/repositories/history_repository.dart';
import '../../../../core/storage/repositories/media_repository.dart';
import '../../../../shared/utils/format.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final services = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            tooltip: 'Clear history',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () async {
              await services.history.clearAll();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('History cleared')),
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<PlayHistoryData>>(
        stream: services.history.watchRecent(),
        builder: (context, snapshot) {
          final entries = snapshot.data ?? const <PlayHistoryData>[];
          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history,
                      size: 72, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text('Nothing played yet',
                      style: theme.textTheme.titleLarge),
                ],
              ),
            );
          }
          return FutureBuilder<Map<String, MediaItem?>>(
            future: _resolveMedia(services, entries),
            builder: (context, mediaSnapshot) {
              final mediaMap = mediaSnapshot.data ?? {};
              return ListView.builder(
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final item = mediaMap[entry.mediaId];
                  return ListTile(
                    leading: Icon(
                      item?.mediaType == 0
                          ? Icons.movie_outlined
                          : Icons.music_note_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(item != null
                        ? item.title ?? item.fileName
                        : entry.mediaId),
                    subtitle: Text(
                      '${Fmt.date(DateTime.fromMillisecondsSinceEpoch(entry.playedAt))}'
                      ' · ${Fmt.duration(Duration(milliseconds: entry.durationPlayed))}',
                    ),
                    trailing: entry.completed
                        ? Icon(Icons.check_circle_outline,
                            color: theme.colorScheme.primary)
                        : null,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<Map<String, MediaItem?>> _resolveMedia(
    AppServices services,
    List<PlayHistoryData> entries,
  ) async {
    final result = <String, MediaItem?>{};
    for (final e in entries.take(50)) {
      result[e.mediaId] ??= await services.media.byId(e.mediaId);
    }
    return result;
  }
}
