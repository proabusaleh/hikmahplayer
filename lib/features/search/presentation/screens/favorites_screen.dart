import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../core/storage/repositories/media_repository.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: StreamBuilder<List<MediaItem>>(
        stream: AppScope.of(context).media.watchFavorites(),
        builder: (context, snapshot) {
          final items = snapshot.data ?? const <MediaItem>[];
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border,
                      size: 72, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text('No favorites yet', style: theme.textTheme.titleLarge),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                leading: Icon(
                  item.mediaType == 0
                      ? Icons.movie_outlined
                      : Icons.music_note_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: Text(item.title ?? item.fileName),
                subtitle: Text(item.folderName ?? ''),
              );
            },
          );
        },
      ),
    );
  }
}
