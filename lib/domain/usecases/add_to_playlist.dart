import '../repositories/playlist_repository.dart';

class AddToPlaylist {
  const AddToPlaylist(this._repository);

  final PlaylistRepository _repository;

  Future<void> call({
    required String playlistId,
    required List<String> mediaIds,
  }) async {
    for (final mediaId in mediaIds) {
      await _repository.addMedia(playlistId, mediaId);
    }
  }
}
