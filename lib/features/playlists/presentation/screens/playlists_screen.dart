import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../core/storage/repositories/playlist_repository.dart';
import '../../../../shared/utils/format.dart';
class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  PlaylistRepository? _playlists;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _playlists ??= AppScope.of(context).playlists;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Playlists')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/home/playlists/create'),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Playlist>>(
        stream: _playlists!.watchAll(),
        builder: (context, snapshot) {
          final playlists = snapshot.data ?? const <Playlist>[];
          if (playlists.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.playlist_add,
                    size: 72,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text('No playlists', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Text(
                      'Create your first playlist to group videos and '
                      'music the way you like.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              return ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    playlist.isAuto ? Icons.auto_awesome : Icons.queue_music,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                title: Text(playlist.name),
                subtitle: Text(
                  '${playlist.itemCount} items · '
                  '${Fmt.duration(Duration(milliseconds: playlist.totalDuration))}',
                ),
                onTap: () => context.push('/home/playlists/${playlist.id}'),
              );
            },
          );
        },
      ),
    );
  }
}
