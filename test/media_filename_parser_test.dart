import 'package:flutter_test/flutter_test.dart';
import 'package:hikmahplayer/core/utils/media_filename_parser.dart';

void main() {
  group('MediaFilenameParser', () {
    test('extracts simple title', () {
      final parsed = MediaFilenameParser.parse('The Art of Listening.mp4');
      expect(parsed.title, 'The Art of Listening');
      expect(parsed.year, isNull);
      expect(parsed.isSeries, isFalse);
    });

    test('extracts season/episode (S01E02)', () {
      final parsed =
          MediaFilenameParser.parse('The.Wisdom.Series.S01E02.mkv');
      expect(parsed.title, 'The Wisdom Series');
      expect(parsed.season, 1);
      expect(parsed.episode, 2);
      expect(parsed.isSeries, isTrue);
    });

    test('extracts season/episode (1x03)', () {
      final parsed = MediaFilenameParser.parse('Lecture 2x03 part one.mp4');
      expect(parsed.season, 2);
      expect(parsed.episode, 3);
      expect(parsed.isSeries, isTrue);
    });

    test('extracts episode word form', () {
      final parsed = MediaFilenameParser.parse('Podcast Episode 42.mp3');
      expect(parsed.episode, 42);
      expect(parsed.isSeries, isTrue);
    });

    test('extracts year', () {
      final parsed = MediaFilenameParser.parse('Favorites of 2024.mp4');
      expect(parsed.year, 2024);
      expect(parsed.title, 'Favorites of');
    });

    test('strips resolution and release tags', () {
      final parsed =
          MediaFilenameParser.parse('Seeking Truth [1080p] (2019).mkv');
      expect(parsed.year, 2019);
      expect(parsed.title.contains('1080p'), isFalse);
      expect(parsed.title.toLowerCase(), contains('truth'));
    });

    test('ignores extension in parsing', () {
      final parsed = MediaFilenameParser.parse('Quiet Moments.flac');
      expect(parsed.title, 'Quiet Moments');
    });
  });
}
