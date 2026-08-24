import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/storage/repositories/playlist_repository.dart';
import 'services_provider.dart';

/// CRUD + membership management over the shared [PlaylistRepository].
///
/// The playlist list is mirrored from the database stream imperatively so
/// mutations can safely use `ref.read` at any time.
class PlaylistManager extends AsyncNotifier<List<Playlist>> {
  static const Uuid _uuid = Uuid();

  StreamSubscription<List<Playlist>>? _subscription;
  var _active = true;

  @override
  Future<List<Playlist>> build() {
    final completer = Completer<List<Playlist>>();
    final stream = ref.read(appServicesProvider).playlists.watchAll();
    _subscription = stream.listen((items) {
      if (!completer.isCompleted) {
        completer.complete(items);
      } else if (_active) {
        state = AsyncData(items);
      }
    }, onError: (Object error, StackTrace stackTrace) {
      if (!completer.isCompleted) {
        completer.completeError(error, stackTrace);
      }
    });
    ref.onDispose(() {
      _active = false;
      _subscription?.cancel();
    });
    return completer.future;
  }

  Future<void> create(String name, {String description = ''}) {
    final repository = ref.read(appServicesProvider).playlists;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return Future<void>.value();
    return repository.create(
      id: _uuid.v4(),
      name: trimmed,
      description: description.trim().isEmpty ? null : description.trim(),
    );
  }

  Future<void> delete(String playlistId) =>
      ref.read(appServicesProvider).playlists.remove(playlistId);

  /// Adds [mediaId] to [playlistId]; duplicates are rejected by the
  /// repository and yield `false`.
  Future<bool> addMedia({
    required String playlistId,
    required String mediaId,
  }) {
    return ref.read(appServicesProvider).playlists.addMedia(
          itemId: _uuid.v4(),
          playlistId: playlistId,
          mediaId: mediaId,
        );
  }

  Future<void> removeMedia({
    required String playlistId,
    required String mediaId,
  }) {
    return ref
        .read(appServicesProvider)
        .playlists
        .removeMedia(playlistId, mediaId);
  }

  /// Reorders a playlist so its items follow [orderedMediaIds].
  ///
  /// The repository reorders playlist-item rows; this translates the media
  /// order into matching row order. Media absent from [orderedMediaIds]
  /// keep their relative order after the ranked ones.
  Future<void> reorder({
    required String playlistId,
    required List<String> orderedMediaIds,
  }) async {
    final repository = ref.read(appServicesProvider).playlists;
    final items = await repository.items(playlistId);
    final rank = <String, int>{
      for (var i = 0; i < orderedMediaIds.length; i++) orderedMediaIds[i]: i,
    };
    final ordered = [...items]..sort((a, b) {
        final rankA =
            rank[a.mediaId] ?? a.sortOrder + orderedMediaIds.length;
        final rankB =
            rank[b.mediaId] ?? b.sortOrder + orderedMediaIds.length;
        return rankA.compareTo(rankB);
      });
    await repository.reorder(playlistId, [
      for (final item in ordered) item.id,
    ]);
  }
}

final playlistManagerProvider =
    AsyncNotifierProvider<PlaylistManager, List<Playlist>>(
  PlaylistManager.new,
);
