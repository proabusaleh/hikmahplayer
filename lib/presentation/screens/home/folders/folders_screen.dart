import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/media_item_extensions.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/utils/file_size_formatter.dart';
import '../../../providers/folder_provider.dart';
import 'widgets/folder_tile.dart';

class FoldersScreen extends ConsumerWidget {
  const FoldersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folders = ref.watch(foldersListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Folders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.pushNamed(context, '/search');
            },
          ),
        ],
      ),
      body: folders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_off_outlined,
                      size: 64,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withOpacity(0.4)),
                  const SizedBox(height: 16),
                  Text('No Folders Found',
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: AppDimensions.sm),
              itemCount: folders.length,
              itemBuilder: (context, index) {
                return FolderTile(
                  folder: folders[index],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FolderContentsScreen(
                          folderPath: folders[index].path,
                          folderName: folders[index].name,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class FolderContentsScreen extends ConsumerWidget {
  final String folderPath;
  final String folderName;

  const FolderContentsScreen({
    super.key,
    required this.folderPath,
    required this.folderName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = ref.watch(folderMediaProvider(folderPath));

    return Scaffold(
      appBar: AppBar(
        title: Text(folderName),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            tooltip: 'Play All',
            onPressed: () {
              ref.read(folderMediaProvider(folderPath));
              // TODO: Play all in folder
            },
          ),
          PopupMenuButton<String>(
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'sort', child: Text('Sort')),
              const PopupMenuItem(
                  value: 'hide', child: Text('Hide Folder')),
            ],
          ),
        ],
      ),
      body: media.isEmpty
          ? const Center(child: Text('Empty folder'))
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: AppDimensions.sm),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.md,
                    vertical: AppDimensions.sm,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.folder,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${media.where((m) => m.isVideo).length} videos, '
                        '${media.where((m) => m.isAudio).length} audio',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                ...media.map((item) => ListTile(
                      leading: Icon(
                        item.isVideo ? Icons.movie : Icons.music_note,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(
                        item.displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${item.format} \u2022 ${FileSizeFormatter.format(item.safeFileSize)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      trailing: Text(
                        item.safeDuration.inSeconds > 0
                            ? '${item.safeDuration.inMinutes}:${(item.safeDuration.inSeconds % 60).toString().padLeft(2, '0')}'
                            : '',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      onTap: () {},
                    )),
              ],
            ),
    );
  }
}
