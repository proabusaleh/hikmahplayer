import '../entities/media_item.dart';
import '../repositories/media_repository.dart';

class GetAllAudio {
  const GetAllAudio(this._repository);

  final MediaRepository _repository;

  Future<List<MediaItem>> call() => _repository.getAllAudio();
}
