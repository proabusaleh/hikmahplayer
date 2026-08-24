import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/media_item.dart';

class Favorites extends AsyncNotifier<List<MediaItem>> {
  @override
  Future<List<MediaItem>> build() async => const [];

  Future<void> toggle(MediaItem media) async {
    throw UnimplementedError();
  }

  bool isFavorite(String mediaId) =>
      state.valueOrNull?.any((item) => item.id == mediaId) ?? false;
}

final favoritesProvider =
    AsyncNotifierProvider<Favorites, List<MediaItem>>(Favorites.new);

final favoriteIdsProvider = Provider<Set<String>>((ref) {
  final favorites = ref.watch(favoritesProvider).valueOrNull;
  return favorites?.map((item) => item.id).toSet() ?? const <String>{};
});
