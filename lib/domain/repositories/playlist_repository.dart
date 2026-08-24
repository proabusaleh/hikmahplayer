import '../entities/playlist.dart';

abstract class PlaylistRepository {
  Future<List<Playlist>> getAllPlaylists();
  Future<Playlist> createPlaylist(String name, {String description = ''});
  Future<void> deletePlaylist(String id);
  Future<void> addMedia(String playlistId, String mediaId);
  Future<void> removeMedia(String playlistId, String mediaId);
  Future<void> reorderMedia(String playlistId, List<String> orderedMediaIds);
}
