import 'package:flutter_test/flutter_test.dart';
import 'package:hikmahplayer/features/player/domain/models/media_item.dart';

void main() {
  group('MediaItem', () {
    late MediaItem videoItem;
    late MediaItem audioItem;

    setUp(() {
      videoItem = const MediaItem(
        id: 'v1',
        title: 'Test Video',
        uri: '/storage/video.mp4',
        type: MediaType.video,
        source: MediaSource.file,
        duration: Duration(minutes: 10),
        fileSize: 524288000,
      );

      audioItem = const MediaItem(
        id: 'a1',
        title: 'Beautiful Song',
        uri: '/storage/song.mp3',
        type: MediaType.audio,
        source: MediaSource.file,
        duration: Duration(minutes: 4, seconds: 30),
        fileSize: 8388608,
        artist: 'Test Artist',
        album: 'Test Album',
      );
    });

    test('equality based on id', () {
      const item1 = MediaItem(id: '1', title: 'A', uri: '/a.mp4');
      const item2 = MediaItem(id: '1', title: 'B', uri: '/b.mp4');
      const item3 = MediaItem(id: '2', title: 'A', uri: '/a.mp4');

      expect(item1, equals(item2));
      expect(item1 == item3, false);
    });

    test('title is displayed', () {
      expect(videoItem.title, 'Test Video');
      expect(audioItem.title, 'Beautiful Song');
    });

    test('artist and album are stored', () {
      expect(audioItem.artist, 'Test Artist');
      expect(audioItem.album, 'Test Album');
      expect(videoItem.artist, null);
    });

    test('copyWith preserves fields', () {
      final updated = videoItem.copyWith(title: 'Updated Title');
      expect(updated.title, 'Updated Title');
      expect(updated.uri, videoItem.uri);
      expect(updated.type, videoItem.type);
    });

    test('toJson/fromJson round trip', () {
      final json = audioItem.toJson();
      final restored = MediaItem.fromJson(json);
      expect(restored.id, audioItem.id);
      expect(restored.title, audioItem.title);
      expect(restored.artist, audioItem.artist);
      expect(restored.duration, audioItem.duration);
    });
  });
}
