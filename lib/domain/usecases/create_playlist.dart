import '../entities/playlist.dart';
import '../repositories/playlist_repository.dart';

class CreatePlaylist {
  const CreatePlaylist(this._repository);

  final PlaylistRepository _repository;

  Future<Playlist> call(String name, {String description = ''}) async {
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', 'Playlist name cannot be empty');
    }
    return _repository.createPlaylist(name.trim(), description: description);
  }
}
