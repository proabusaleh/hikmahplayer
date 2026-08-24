import '../entities/media_item.dart';
import '../entities/sort_option.dart';

abstract class MediaRepository {
  Future<List<MediaItem>> getAllVideos({SortConfig? sort});
  Future<List<MediaItem>> getAllAudio({SortConfig? sort});
  Future<List<MediaItem>> getByFolder(String folderPath, {SortConfig? sort});
  Future<MediaItem?> getById(String id);
  Future<List<MediaItem>> search(String query, {MediaTypeFilter? typeFilter});
  Future<void> toggleFavorite(String id);
  Future<Set<String>> getFavoriteIds();
}

enum MediaTypeFilter { all, videos, audio }
