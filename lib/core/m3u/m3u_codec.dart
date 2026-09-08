/// Pure-Dart M3U playlist codec (import + export).
///
/// M3U playlists are plain text: a leading `#EXTM3U` header, one `#EXTINF`
/// metadata line per entry followed by the media path/URI line, and optional
/// comments (`#...`). This codec parses the widely-used format and can
/// serialize entries back to it. It has no dependency on the media database,
/// so it is fully unit-testable.
library;

/// A single parsed M3U entry.
class M3uEntry {
  const M3uEntry({
    required this.path,
    this.durationSeconds,
    this.title,
  });

  /// The media path or URI line (plain text as written in the file).
  final String path;

  /// Duration advertised by `#EXTINF`, in whole seconds; `null` when unknown.
  final int? durationSeconds;

  /// Optional title advertised by `#EXTINF`.
  final String? title;

  /// True when the entry could be resolved to a concrete file name.
  String get fileName {
    final index = path.lastIndexOf(RegExp(r'[/\\]'));
    return path.substring(index + 1);
  }
}

/// Parses the content of an `.m3u` file into ordered [M3uEntry] values.
///
/// Non-media lines such as `#EXTM3U`, `#EXTGRP`, `#PLAYLIST` and other
/// comments are skipped. `#EXTINF` metadata is attached to the following
/// media line.
List<M3uEntry> parseM3u(String content) {
  final entries = <M3uEntry>[];
  var pendingSeconds = 0;
  var pendingTitle = '';

  for (final line in content.split(RegExp(r'\r?\n'))) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;

    if (trimmed.startsWith('#EXTINF:')) {
      final meta = trimmed.substring('#EXTINF:'.length);
      final comma = meta.indexOf(',');
      final rawDuration =
          (comma >= 0 ? meta.substring(0, comma) : meta).trim();
      pendingSeconds = int.tryParse(rawDuration) ?? 0;
      pendingTitle = comma >= 0 ? meta.substring(comma + 1).trim() : '';
      continue;
    }

    if (trimmed.startsWith('#')) continue;

    entries.add(
      M3uEntry(
        path: trimmed,
        durationSeconds: pendingSeconds > 0 ? pendingSeconds : null,
        title: pendingTitle.isEmpty ? null : pendingTitle,
      ),
    );
    pendingSeconds = 0;
    pendingTitle = '';
  }

  return entries;
}

/// Serializes [entries] to standard M3U text (header + EXTINF + path lines).
String buildM3u(Iterable<M3uEntry> entries) {
  final buffer = StringBuffer()..writeln('#EXTM3U');
  for (final entry in entries) {
    buffer
      ..writeln(
        '#EXTINF:${entry.durationSeconds ?? 0},${entry.title ?? entry.fileName}',
      )
      ..writeln(entry.path);
  }
  return buffer.toString();
}