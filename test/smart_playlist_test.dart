import 'package:flutter_test/flutter_test.dart';
import 'package:hikmahplayer/features/library/domain/models/library_item.dart';
import 'package:hikmahplayer/features/library/domain/models/smart_playlist.dart';
import 'package:hikmahplayer/features/player/domain/models/media_item.dart';

LibraryItem _item({
  required String id,
  String? title,
  MediaType type = MediaType.video,
  double? rating,
  int? year,
  List<String> genres = const [],
  Set<String> tags = const {},
  bool favorite = false,
  Duration? lastPosition,
  Duration? duration,
  int? playCount,
}) {
  return LibraryItem(
    media: MediaItem(
      id: id,
      title: title ?? id,
      uri: 'file:///tmp/$id.mp4',
      type: type,
      genres: genres,
      year: year,
      duration: duration,
      lastPosition: lastPosition,
      isFavorite: favorite,
    ),
    tags: tags,
    rating: rating,
    playCount: playCount ?? 0,
    lastScannedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  final scifiFav = _item(
    id: 'a',
    title: 'Arrival',
    genres: ['Sci-fi'],
    rating: 8.2,
    year: 2016,
    favorite: true,
  );
  final unwatchedLecture = _item(
    id: 'b',
    title: 'Lecture 1',
    tags: {'lecture'},
    year: 2024,
  );
  final watched2024 = _item(
    id: 'c',
    title: 'Favorite of 2024',
    year: 2024,
    favorite: true,
    lastPosition: const Duration(minutes: 120),
    duration: const Duration(minutes: 120),
  );
  final sadShort = _item(
    id: 'd',
    title: 'Sad',
    genres: ['Sci-fi'],
    rating: 5.5,
    duration: const Duration(minutes: 10),
  );

  group('SmartPlaylistMatcher', () {
    test('matches combined rules (all)', () {
      final playlist = SmartPlaylist(
        id: 'p1',
        name: 'Sci-fi > 8.0',
        rules: [
          SmartRule.hasGenre('Sci-fi'),
          SmartRule.ratingAtLeast(8.0),
        ],
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      expect(SmartPlaylistMatcher.matches(scifiFav, playlist), isTrue);
      expect(SmartPlaylistMatcher.matches(sadShort, playlist), isFalse);
    });

    test('unwatched lectures', () {
      final playlist = SmartPlaylist(
        id: 'p2',
        name: 'Unwatched lectures',
        rules: [
          SmartRule.hasTag('lecture'),
          SmartRule.unwatched(),
        ],
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      expect(SmartPlaylistMatcher.matches(unwatchedLecture, playlist), isTrue);
      // Watched 2024 favourite is not unwatched.
      expect(SmartPlaylistMatcher.matches(watched2024, playlist), isFalse);
    });

    test('favorites from 2024', () {
      final playlist = SmartPlaylist(
        id: 'p3',
        name: 'Favorites from 2024',
        rules: [
          SmartRule.isFavorite(),
          SmartRule.year(2024),
        ],
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      expect(SmartPlaylistMatcher.matches(watched2024, playlist), isTrue);
      expect(SmartPlaylistMatcher.matches(scifiFav, playlist), isFalse);
    });

    test('any connective', () {
      final playlist = SmartPlaylist(
        id: 'p4',
        name: 'Either',
        connective: LogicalConnective.any,
        rules: [
          SmartRule.isFavorite(),
          SmartRule.hasGenre('Sci-fi'),
        ],
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      expect(SmartPlaylistMatcher.matches(scifiFav, playlist), isTrue);
      expect(SmartPlaylistMatcher.matches(sadShort, playlist), isTrue);
      expect(SmartPlaylistMatcher.matches(unwatchedLecture, playlist), isFalse);
    });

    test('between and comparison operators', () {
      const between = SmartRule(
        field: SmartField.rating,
        operator: SmartOperator.between,
        value: 8.0,
        value2: 9.0,
      );
      expect(SmartPlaylistMatcher.matchesRule(scifiFav, between), isTrue);
      expect(SmartPlaylistMatcher.matchesRule(sadShort, between), isFalse);

      const longerThan = SmartRule(
        field: SmartField.duration,
        operator: SmartOperator.greaterThan,
        value: 60 * 60,
      );
      expect(SmartPlaylistMatcher.matchesRule(watched2024, longerThan), isTrue);
      expect(SmartPlaylistMatcher.matchesRule(sadShort, longerThan), isFalse);
    });

    test('empty/notEmpty on unrated items', () {
      const unrated = SmartRule(
        field: SmartField.rating,
        operator: SmartOperator.empty,
      );
      expect(SmartPlaylistMatcher.matchesRule(unwatchedLecture, unrated), isTrue);
      expect(SmartPlaylistMatcher.matchesRule(scifiFav, unrated), isFalse);
    });

    test('JSON round-trip', () {
      final playlist = SmartPlaylist(
        id: 'p5',
        name: 'Round trip',
        rules: [
          SmartRule.hasGenre('Sci-fi'),
          SmartRule.ratingAtLeast(8.0),
        ],
        sort: const SmartSort(field: SmartField.year, ascending: false),
        limit: 25,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 2),
      );
      final restored = SmartPlaylist.fromJson(playlist.toJson());
      expect(restored.id, 'p5');
      expect(restored.rules.length, 2);
      expect(restored.sort?.field, SmartField.year);
      expect(restored.sort?.ascending, isFalse);
      expect(restored.limit, 25);
    });
  });
}
