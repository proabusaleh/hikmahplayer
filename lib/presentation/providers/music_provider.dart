import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/repositories/media_repository.dart';
import 'media_provider.dart';

enum MusicTab { songs, albums, artists }

final musicTabIndexProvider = StateProvider<MusicTab>((ref) => MusicTab.songs);

final albumsGroupedProvider = Provider<Map<String, List<MediaItem>>>((ref) {
  final audios = ref.watch(audioListProvider);
  final Map<String, List<MediaItem>> albums = {};
  for (final audio in audios) {
    final albumName = audio.album ?? 'Unknown Album';
    albums.putIfAbsent(albumName, () => []).add(audio);
  }
  final sorted = Map.fromEntries(
    albums.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
  );
  return sorted;
});

final artistsGroupedProvider = Provider<Map<String, List<MediaItem>>>((ref) {
  final audios = ref.watch(audioListProvider);
  final Map<String, List<MediaItem>> artists = {};
  for (final audio in audios) {
    final artistName = audio.artist ?? 'Unknown Artist';
    artists.putIfAbsent(artistName, () => []).add(audio);
  }
  final sorted = Map.fromEntries(
    artists.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
  );
  return sorted;
});
