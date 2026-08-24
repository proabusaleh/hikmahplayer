import '../entities/folder.dart';
import '../entities/media_item.dart';
import '../repositories/media_repository.dart';

class GetFolders {
  const GetFolders(this._repository);

  final MediaRepository _repository;

  Future<List<Folder>> call() async {
    final media = await _repository.getAllVideos();
    return buildFolders(media);
  }

  List<Folder> buildFolders(List<MediaItem> media) {
    final byFolder = <String, List<MediaItem>>{};
    for (final item in media) {
      byFolder.putIfAbsent(item.folderPath, () => []).add(item);
    }
    return byFolder.entries
        .map(
          (entry) => Folder(
            path: entry.key,
            mediaCount: entry.value.length,
            thumbnailMediaId: entry.value.first.id,
          ),
        )
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }
}
