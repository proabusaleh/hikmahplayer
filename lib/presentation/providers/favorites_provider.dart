import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/repositories/media_repository.dart';
import 'services_provider.dart';

class Favorites extends AsyncNotifier<List<MediaItem>> {
  // Database writes must refresh the list, not invalidate this notifier
  // mid-mutation — so the stream is subscribed imperatively instead of being
  // watched as a provider dependency.
  StreamSubscription<List<MediaItem>>? _subscription;
  var _active = true;

  @override
  Future<List<MediaItem>> build() {
    final completer = Completer<List<MediaItem>>();
    final stream = ref.read(appServicesProvider).media.watchFavorites();
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

  /// Flips the favorite flag of [media]; the mirrored stream refreshes the
  /// state.
  Future<void> toggle(MediaItem media) async {
    final repository = ref.read(appServicesProvider).media;
    final isFavorite =
        state.valueOrNull?.any((m) => m.id == media.id) ?? false;
    await repository.setFavorite(media.id, !isFavorite);
  }

  bool isFavorite(String mediaId) =>
      state.valueOrNull?.any((item) => item.id == mediaId) ?? false;
}

final favoritesProvider =
    AsyncNotifierProvider<Favorites, List<MediaItem>>(Favorites.new);

/// Fast membership lookups for grids/lists (avoids O(n) scans per tile).
final favoriteIdsProvider = Provider<Set<String>>((ref) {
  final favorites = ref.watch(favoritesProvider).valueOrNull;
  return favorites?.map((item) => item.id).toSet() ?? const <String>{};
});
