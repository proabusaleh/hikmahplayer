import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/playlist.dart';

class PlaylistManager extends AsyncNotifier<List<Playlist>> {
  @override
  Future<List<Playlist>> build() async => const [];

  Future<void> create(String name, {String description = ''}) async {
    throw UnimplementedError();
  }

  Future<void> delete(String playlistId) async {
    throw UnimplementedError();
  }

  Future<void> addMedia({
    required String playlistId,
    required String mediaId,
  }) async {
    throw UnimplementedError();
  }

  Future<void> removeMedia({
    required String playlistId,
    required String mediaId,
  }) async {
    throw UnimplementedError();
  }

  Future<void> reorder({
    required String playlistId,
    required List<String> orderedMediaIds,
  }) async {
    throw UnimplementedError();
  }
}

final playlistManagerProvider =
    AsyncNotifierProvider<PlaylistManager, List<Playlist>>(
  PlaylistManager.new,
);
