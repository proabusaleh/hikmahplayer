import 'package:hikmahplayer/features/player/domain/models/media_item.dart';

/// Size accounting for one group of media sharing a property (codec,
/// resolution, ...).
class UsageBucket {
  final int count;
  final int totalBytes;

  const UsageBucket({required this.count, required this.totalBytes});

  UsageBucket add(int bytes) => UsageBucket(
        count: count + 1,
        totalBytes: totalBytes + bytes,
      );

  Map<String, dynamic> toJson() => {'count': count, 'totalBytes': totalBytes};

  factory UsageBucket.fromJson(Map<String, dynamic> json) => UsageBucket(
        count: json['count'] as int,
        totalBytes: json['totalBytes'] as int,
      );
}

/// Aggregated storage analysis for the library (section 3.1 "Storage
/// analysis: codec distribution, resolution stats, space usage").
class StorageStats {
  /// Total bytes consumed by indexed media files.
  final int totalBytes;

  /// Total number of indexed media files.
  final int totalFiles;

  /// Count of items per [MediaType].
  final Map<MediaType, int> countByType;

  /// Count and bytes grouped by video/audio codec.
  final Map<String, UsageBucket> byCodec;

  /// Count and bytes grouped by video height (e.g. 480, 720, 1080, 2160).
  final Map<int, UsageBucket> byResolution;

  /// The largest files, sorted descending by size.
  final List<MediaItem> largestFiles;

  const StorageStats({
    this.totalBytes = 0,
    this.totalFiles = 0,
    this.countByType = const {},
    this.byCodec = const {},
    this.byResolution = const {},
    this.largestFiles = const [],
  });

  /// Formatted total size, e.g. `1.42 GB`.
  String get formattedTotal {
    return formatBytes(totalBytes);
  }

  /// Human readable byte formatting for the stats UI.
  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var value = bytes.toDouble();
    var index = 0;
    while (value >= 1024 && index < suffixes.length - 1) {
      value /= 1024;
      index++;
    }
    final precision = value >= 100 ? 0 : (value >= 10 ? 1 : 2);
    return '${value.toStringAsFixed(precision)} ${suffixes[index]}';
  }

  /// The highest resolution present (by pixel count), or `null`.
  String? get dominantResolution {
    if (byResolution.isEmpty) return null;
    final sorted = byResolution.keys.toList()..sort((a, b) => b.compareTo(a));
    return sorted.first >= 2160
        ? '4K'
        : sorted.first >= 1440
            ? '2K'
            : '${sorted.first}p';
  }

  @override
  String toString() =>
      'StorageStats(files: $totalFiles, total: $formattedTotal)';
}
