/// One synchronised lyric line.
class SyncedLyricLine {
  final Duration timestamp;
  final String text;

  const SyncedLyricLine({required this.timestamp, required this.text});

  @override
  String toString() => '$timestamp $text';
}

/// Parses LRC (`[mm:ss.xx]`) lyric files and keeps them synchronised with
/// playback, in pure Dart.
class LrcParser {
  const LrcParser();

  static final RegExp _tag = RegExp(r'\[(\d{1,3}):(\d{2})(?:[.:](\d{1,3}))?\]');

  List<SyncedLyricLine> parse(String content) {
    final lines = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final result = <SyncedLyricLine>[];

    for (final rawLine in lines.split('\n')) {
      final timestamps = <Duration>[];
      final buffer = StringBuffer();
      var index = 0;
      while (index < rawLine.length) {
        final match = _tag.matchAsPrefix(rawLine, index);
        if (match != null) {
          final minutes = int.parse(match.group(1)!);
          final seconds = int.parse(match.group(2)!);
          var millis = 0;
          final msRaw = match.group(3);
          if (msRaw != null) {
            // Support both `.xx` (centiseconds) and `.xxx` (milliseconds).
            millis = msRaw.length == 3
                ? int.parse(msRaw)
                : int.parse(msRaw) * 10;
          }
          timestamps.add(
              Duration(minutes: minutes, seconds: seconds, milliseconds: millis));
          index += match.end - match.start;
        } else {
          buffer.write(rawLine[index]);
          index++;
        }
      }
      final text = buffer.toString().trim();
      if (timestamps.isEmpty || text.isEmpty) continue;
      for (final ts in timestamps) {
        result.add(SyncedLyricLine(timestamp: ts, text: text));
      }
    }

    result.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return result;
  }
}

/// Finds the lyric line active at a playback position.
class LyricsSynchronizer {
  const LyricsSynchronizer();

  SyncedLyricLine? lineAt(List<SyncedLyricLine> lines, Duration position) {
    if (lines.isEmpty) return null;
    SyncedLyricLine? current;
    for (final line in lines) {
      if (line.timestamp > position) break;
      current = line;
    }
    return current;
  }
}
