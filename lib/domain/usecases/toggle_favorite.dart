import '../repositories/media_repository.dart';

class ToggleFavorite {
  const ToggleFavorite(this._repository);

  final MediaRepository _repository;

  Future<void> call(String mediaId) => _repository.toggleFavorite(mediaId);
}
