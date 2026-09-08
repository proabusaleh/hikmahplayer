import 'package:flutter_test/flutter_test.dart';
import 'package:hikmahplayer/core/m3u/m3u_codec.dart';

void main() {
  group('parseM3u', () {
    test('parses EXTINF entries with title and duration', () {
      const content = '''
#EXTM3U
#EXTINF:183,Artist - Song
/audio/song.mp3
''';
      final entries = parseM3u(content);
      expect(entries, hasLength(1));
      expect(entries.single.path, '/audio/song.mp3');
      expect(entries.single.durationSeconds, 183);
      expect(entries.single.title, 'Artist - Song');
    });

    test('tolerates CRLF line endings', () {
      const content = '#EXTM3U\r\n#EXTINF:10,Track\r\nC:/music/track.mp3\r\n';
      final entries = parseM3u(content);
      expect(entries, hasLength(1));
      expect(entries.single.path, 'C:/music/track.mp3');
      expect(entries.single.title, 'Track');
    });

    test('skips comments, blank lines and unknown directives', () {
      const content = '''
#EXTM3U
#EXTINF:183,Artist - Song
/audio/song.mp3

#EXTINF:-1,
#EXTGRP:Bonus
/audio/bonus.flac
# just a comment
relative.mp3
''';
      final entries = parseM3u(content);
      expect(entries, hasLength(3));
      expect(entries[0].path, '/audio/song.mp3');
      expect(entries[0].durationSeconds, 183);
      expect(entries[0].title, 'Artist - Song');
      expect(entries[1].path, '/audio/bonus.flac');
      expect(entries[1].durationSeconds, isNull);
      expect(entries[1].title, isNull);
      expect(entries[2].path, 'relative.mp3');
    });

    test('keeps media line without preceding EXTINF', () {
      const content = '#EXTM3U\n/plain/path.m4a\n';
      final entries = parseM3u(content);
      expect(entries, hasLength(1));
      expect(entries.single.path, '/plain/path.m4a');
      expect(entries.single.durationSeconds, isNull);
      expect(entries.single.title, isNull);
    });
  });

  group('buildM3u', () {
    test('round-trips parsed entries', () {
      const content = '''
#EXTM3U
#EXTINF:183,Artist - Song
/audio/song.mp3
''';
      final entries = parseM3u(content);
      final rebuilt = parseM3u(buildM3u(entries));
      expect(rebuilt, hasLength(1));
      expect(rebuilt.single.path, '/audio/song.mp3');
      expect(rebuilt.single.durationSeconds, 183);
      expect(rebuilt.single.title, 'Artist - Song');
    });

    test('writes the header and one EXTINF+path pair per entry', () {
      final m3u = buildM3u([
        M3uEntry(
          path: '/a.mp3',
          durationSeconds: 60,
          title: 'A',
        ),
        M3uEntry(path: '/b.mp3'),
      ]);
      expect(m3u.split('\n').first, '#EXTM3U');
      expect(m3u, contains('#EXTINF:60,A\n/a.mp3'));
      expect(m3u, contains('#EXTINF:0,b.mp3\n/b.mp3'));
    });
  });

  group('fileName', () {
    test('extracts the file name from posix, windows and relative paths', () {
      expect(const M3uEntry(path: '/a/b/c.mp3').fileName, 'c.mp3');
      expect(const M3uEntry(path: 'C:\\music\\d.mp3').fileName, 'd.mp3');
      expect(const M3uEntry(path: 'relative.mp3').fileName, 'relative.mp3');
    });
  });
}