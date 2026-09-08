import 'dart:io';

import '../../features/player/domain/models/extended_media_info.dart';
import '../storage/repositories/media_repository.dart';

export '../../features/player/domain/models/extended_media_info.dart';

/// Inspects a persisted library row + live playback state into the 15+ row
/// [ExtendedMediaInfo] shown by the player's media-info sheet.
class MediaInfoService {
  const MediaInfoService();

  Future<ExtendedMediaInfo> inspect({
    required MediaItem row,
    required MediaRepository repository,
    required Duration playbackDuration,
    required String? liveResolution,
  }) async {
    // Fall back to a live file stat when the stored row lacks a size.
    int? size = row.fileSize > 0 ? row.fileSize : null;
    if (size == null) {
      try {
        final file = File(row.filePath);
        if (await file.exists()) {
          final stat = await file.stat();
          size = stat.size;
        }
      } catch (_) {}
    }

    final resolution = liveResolution ??
        (row.width != null && row.height != null
            ? '${row.width}×${row.height}'
            : row.resolution);

    return ExtendedMediaInfo(
      fileSize: size,
      format: row.format,
      resolution: resolution,
      bitrate: row.bitRate,
      sampleRate: row.sampleRate,
      createdAt: row.dateAdded == 0
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.dateAdded),
      modifiedAt: row.dateModified == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.dateModified!),
      playCount: row.playCount,
      lastPlayedAt: row.lastPlayed == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.lastPlayed!),
      audioCodec: null,
      videoCodec: null,
      channels: null,
      fps: null,
    );
  }
}