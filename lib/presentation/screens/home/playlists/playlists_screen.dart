import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_dimensions.dart';
import 'widgets/playlist_card.dart';

class PlaylistEntry {
  final String id;
  final String name;
  final String? description;
  final bool isAuto;
  final int itemCount;
  final Duration totalDuration;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PlaylistEntry({
    required this.id,
    required this.name,
    this.description,
    this.isAuto = false,
    this.itemCount = 0,
    this.totalDuration = Duration.zero,
    required this.createdAt,
    required this.updatedAt,
  });
}

enum PlaylistType { mixed, video, audio }

final playlistListProvider = StateProvider<List<PlaylistEntry>>((ref) => [
      PlaylistEntry(
        id: 'auto_favorites',
        name: 'Favorites',
        isAuto: true,
        itemCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      PlaylistEntry(
        id: 'auto_recent',
        name: 'Recently Played',
        isAuto: true,
        itemCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ]);

class PlaylistsScreen extends ConsumerWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create Playlist',
            onPressed: () => _showCreateDialog(context, ref),
          ),
        ],
      ),
      body: playlists.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.playlist_add,
                      size: 64,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withOpacity(0.4)),
                  const SizedBox(height: 16),
                  Text('No Playlists Yet',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('Create a playlist to organize your media',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          )),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _showCreateDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Playlist'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppDimensions.md),
              itemCount: playlists.length,
              itemBuilder: (context, index) {
                return PlaylistCard(
                  playlist: playlists[index],
                  onTap: () {},
                  onDelete: playlists[index].isAuto
                      ? null
                      : () {
                          final list =
                              List<PlaylistEntry>.from(playlists);
                          list.removeAt(index);
                          ref.read(playlistListProvider.notifier).state =
                              list;
                        },
                );
              },
            ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    PlaylistType selectedType = PlaylistType.mixed;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Create Playlist'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Playlist Name *',
                  hintText: 'e.g., Quran Videos',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<PlaylistType>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(
                    value: PlaylistType.mixed,
                    child: Text('Mixed (Video + Audio)'),
                  ),
                  DropdownMenuItem(
                    value: PlaylistType.video,
                    child: Text('Video Only'),
                  ),
                  DropdownMenuItem(
                    value: PlaylistType.audio,
                    child: Text('Audio Only'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => selectedType = value);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                final newPlaylist = PlaylistEntry(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  description: descController.text.trim().isEmpty
                      ? null
                      : descController.text.trim(),
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                final list =
                    List<PlaylistEntry>.from(ref.read(playlistListProvider));
                list.add(newPlaylist);
                ref.read(playlistListProvider.notifier).state = list;
                Navigator.pop(ctx);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}
