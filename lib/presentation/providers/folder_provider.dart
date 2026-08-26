import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/extensions/media_item_extensions.dart';
import '../../domain/entities/folder.dart';
import '../../features/player/domain/models/media_item.dart';
import 'media_provider.dart';

final foldersListProvider = Provider<List<Folder>>((ref) {
  final videos = ref.watch(videosListProvider);
  final audios = ref.watch(audioListProvider);
  final allMedia = [...videos, ...audios];

  final Map<String, List<MediaItem>> folderMap = {};
  for (final item in allMedia) {
    folderMap.putIfAbsent(item.folderPath, () => []).add(item);
  }

  final folders = folderMap.entries.map((entry) {
    final path = entry.key;
    final name = path.split(RegExp(r'[/\\]')).last;
    return Folder(
      id: path.hashCode.toString(),
      path: path,
      name: name,
      mediaCount: entry.value.length,
      createdAt: DateTime.now(),
    );
  }).toList();

  folders.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return folders;
});

final folderMediaProvider = Provider.family<List<MediaItem>, String>((ref, folderPath) {
  final videos = ref.watch(videosListProvider);
  final audios = ref.watch(audioListProvider);
  final allMedia = [...videos, ...audios];
  return allMedia
      .where((m) => m.folderPath == folderPath)
      .toList()
    ..sort((a, b) => a.fileName.compareTo(b.fileName));
});
