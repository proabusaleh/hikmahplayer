import '../entities/media_item.dart';
import '../repositories/media_repository.dart';

class SearchMedia {
  const SearchMedia(this._repository);

  final MediaRepository _repository;

  Future<List<MediaItem>> call(
    String query, {
    MediaTypeFilter typeFilter = MediaTypeFilter.all,
  }) async {
    if (query.trim().isEmpty) return const [];
    return _repository.search(query.trim(), typeFilter: typeFilter);
  }
}
