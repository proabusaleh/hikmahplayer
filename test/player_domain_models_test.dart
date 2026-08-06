import 'package:flutter_test/flutter_test.dart';
import 'package:hikmahplayer/features/player/domain/models/bookmark.dart';
import 'package:hikmahplayer/features/player/domain/models/chapter.dart';
import 'package:hikmahplayer/features/player/domain/models/media_item.dart';
import 'package:hikmahplayer/features/player/domain/models/media_track.dart';
import 'package:hikmahplayer/features/player/domain/models/playback_queue.dart';
import 'package:hikmahplayer/features/player/domain/models/playback_settings.dart';
import 'package:hikmahplayer/features/player/domain/models/playlist.dart';

void main() {
  group('MediaItem', () {
    test('JSON round-trip preserves fields', () {
      final original = MediaItem(
        id: 'item-1',
        title: 'The Wisdom Lecture',
        uri: r'C:\media\lecture.mp4',
        type: MediaType.video,
        source: MediaSource.file,
        artist: 'Ustadh',
        album: 'Series',
        genres: const ['Education'],
        year: 2026,
        description: 'A talk on wisdom.',
        artworkUri: 'https://example.com/art.jpg',
        mimeType: 'video/mp4',
        fileSize: 123456789,
        duration: const Duration(minutes: 42),
        width: 1920,
        height: 1080,
        videoCodec: 'h264',
        audioCodec: 'aac',
        bitrate: 2500000,
        startOffset: const Duration(seconds: 5),
        endOffset: const Duration(seconds: 100),
        httpHeaders: const {'Authorization': 'Bearer x'},
        chapters: const [
          Chapter(
            id: 'ch-1',
            title: 'Intro',
            start: Duration.zero,
            end: Duration(minutes: 2),
          ),
        ],
        lastPosition: const Duration(minutes: 10),
        isFavorite: true,
        dateAdded: DateTime.utc(2026, 1, 1),
        lastPlayedAt: DateTime.utc(2026, 2, 2),
        extras: const {'aiTags': ['calm', 'focus']},
      );

      final restored = MediaItem.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.type, MediaType.video);
      expect(restored.source, MediaSource.file);
      expect(restored.duration, original.duration);
      expect(restored.startOffset, original.startOffset);
      expect(restored.endOffset, original.endOffset);
      expect(restored.httpHeaders, original.httpHeaders);
      expect(restored.chapters.length, 1);
      expect(restored.chapters.first.title, 'Intro');
      expect(restored.chapters.first.start, Duration.zero);
      expect(restored.lastPosition, original.lastPosition);
      expect(restored.extras, original.extras);
      expect(restored, original);
    });

    test('copyWith replaces only provided fields', () {
      const item = MediaItem(id: 'i', title: 'T', uri: 'file:///a.mp4');
      final copy = item.copyWith(title: 'Renamed');
      expect(copy.id, 'i');
      expect(copy.title, 'Renamed');
      expect(copy.uri, 'file:///a.mp4');
    });
  });

  group('Chapter', () {
    test('JSON round-trip', () {
      const chapter = Chapter(
        id: 'c1',
        title: 'Chapter 1',
        start: Duration(seconds: 30),
        end: Duration(minutes: 5),
        description: 'desc',
      );
      final restored = Chapter.fromJson(chapter.toJson());
      expect(restored, chapter);
      expect(restored.end, const Duration(minutes: 5));
    });
  });

  group('Bookmark', () {
    test('JSON round-trip', () {
      final bookmark = Bookmark(
        id: 'b1',
        mediaId: 'm1',
        position: const Duration(minutes: 3),
        label: 'Key insight',
        note: 'Remember this',
        colorValue: 0xFF00FF00,
        createdAt: DateTime.utc(2026, 3, 3),
        updatedAt: DateTime.utc(2026, 3, 4),
      );
      final restored = Bookmark.fromJson(bookmark.toJson());
      expect(restored, bookmark);
      expect(restored.position, const Duration(minutes: 3));
      expect(restored.colorValue, 0xFF00FF00);
    });
  });

  group('Playlist', () {
    test('JSON round-trip and mutations', () {
      final playlist = Playlist(
        id: 'p1',
        name: 'Evening Lectures',
        description: 'Playlist desc',
        mediaIds: const ['a', 'b'],
        isPinned: true,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );
      final restored = Playlist.fromJson(playlist.toJson());
      expect(restored, playlist);
      expect(restored.length, 2);

      final added = playlist.addingMedia(['c', 'd']);
      expect(added.mediaIds, ['a', 'b', 'c', 'd']);

      final removed = playlist.removingMedia('a');
      expect(removed.mediaIds, ['b']);
      expect(removed.name, 'Evening Lectures');
    });
  });

  group('PlaybackQueue', () {
    test('empty/single/current resolution', () {
      const item = MediaItem(id: 'q1', title: 'Q', uri: 'file:///q.mp3');
      final queue = PlaybackQueue.single(item);
      expect(queue.length, 1);
      expect(queue.current, item);

      const empty = PlaybackQueue.empty;
      expect(empty.isEmpty, true);
      expect(empty.current, isNull);
    });

    test('copyWith', () {
      const queue = PlaybackQueue(currentIndex: 2);
      final copy = queue.copyWith(shuffle: true);
      expect(copy.shuffle, true);
      expect(copy.currentIndex, 2);
    });
  });

  group('PlaybackSettings', () {
    test('JSON round-trip and defaults', () {
      const settings = PlaybackSettings(
        volume: 0.5,
        speed: 1.5,
        pitch: 1.2,
        repeatMode: RepeatMode.all,
        shuffle: true,
      );
      final restored = PlaybackSettings.fromJson(settings.toJson());
      expect(restored, settings);
      expect(restored.repeatMode, RepeatMode.all);

      const defaults = PlaybackSettings();
      expect(defaults.volume, 1.0);
      expect(defaults.speed, 1.0);
      expect(defaults.repeatMode, RepeatMode.off);
      expect(defaults.rememberPosition, true);
    });
  });

  group('MediaTrack', () {
    test('identity and labels', () {
      const track = MediaTrack(
        type: TrackType.subtitle,
        id: 'sid:0',
        title: 'English',
        language: 'en',
      );
      expect(track.label, 'English');
      expect(track.isExternal, false);
    });
  });
}
