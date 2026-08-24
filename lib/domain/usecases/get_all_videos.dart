import '../entities/media_item.dart';
import '../entities/sort_option.dart';
import '../repositories/media_repository.dart';

class GetAllVideos {
  const GetAllVideos(this._repository);

  final MediaRepository _repository;

  Future<List<MediaItem>> call({SortConfig? sort}) =>
      _repository.getAllVideos(sort: sort);
}
