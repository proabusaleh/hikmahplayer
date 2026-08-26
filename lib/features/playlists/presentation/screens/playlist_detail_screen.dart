import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../core/storage/repositories/playlist_repository.dart';

class PlaylistDetailScreen extends StatelessWidget {
  const PlaylistDetailScreen({super.key, required this.playlistId});

  final String playlistId;

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).playlists;
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () =>
                context.push('/home/playlists/$playlistId/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await repo.remove(playlistId);
              if (context.mounted) context.pop();
            },
          ),
        ],
      ),
      body: FutureBuilder<Playlist?>(
        future: repo.byId(playlistId),
        builder: (context, snapshot) {
          final playlist = snapshot.data;
          return StreamBuilder<List<PlaylistItem>>(
            stream: repo.watchItems(playlistId),
            builder: (context, itemsSnapshot) {
              final items = itemsSnapshot.data ?? const <PlaylistItem>[];
              if (items.isEmpty) {
                return Center(
                  child: Text(
                    playlist == null
                        ? 'Playlist not found'
                        : 'No media in "${playlist.name}" yet',
                  ),
                );
              }
              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text('${index + 1}'),
                    ),
                    title: Text(item.mediaId),
                    subtitle: Text('Order ${item.sortOrder}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () =>
                          repo.removeMedia(playlistId, item.mediaId),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
