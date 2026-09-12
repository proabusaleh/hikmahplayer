import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../storage/media_type.dart';
import '../storage/repositories/media_repository.dart';
import '../utils/media_scanner.dart';

/// Outcome of a [MediaScanService.scanAll] run.
class MediaScanResult {
  const MediaScanResult({
    this.videosFound = 0,
    this.audioFound = 0,
    this.errors = const [],
  });

  final int videosFound;
  final int audioFound;
  final List<String> errors;

  int get totalFound => videosFound + audioFound;

  bool get hasErrors => errors.isNotEmpty;

  @override
  String toString() => 'MediaScanResult(videos: $videosFound, audio: $audioFound'
      '${hasErrors ? ', errors: ${errors.length}' : ''})';
}

/// Preserves the MediaStore library into the persisted drift [MediaItems]
/// table.
///
/// Discovery happens on the native side ([MediaScanner]); this service owns
/// the idempotent upsert that keeps the UI (videos, music, favourites,
/// history...) in sync. Rows are keyed by a stable hash of the `content://`
/// URI, so re-scanning never duplicates an entry and existing playback/favour
/// state is preserved by drift's conflict-on-id upsert.
class MediaScanService {
  MediaScanService(
    this.media, {
    Future<List<ScannedMedia>> Function()? scanVideos,
    Future<List<ScannedMedia>> Function()? scanAudio,
  })  : _scanVideos = scanVideos ?? MediaScanner.scanForVideos,
        _scanAudio = scanAudio ?? MediaScanner.scanForAudio;

  final MediaRepository media;
  final Future<List<ScannedMedia>> Function() _scanVideos;
  final Future<List<ScannedMedia>> Function() _scanAudio;

  /// Scans the device and persists every discovered entry.
  ///
  /// Never throws — failures (missing permission, native bridge error, a
  /// single unreadable row) are collected into [MediaScanResult.errors] so
  /// the scan flow can keep going.
  Future<MediaScanResult> scanAll() async {
    final errors = <String>[];

    List<ScannedMedia> videos = const [];
    List<ScannedMedia> audio = const [];
    try {
      videos = await _scanVideos();
    } catch (error) {
      errors.add('video scan: $error');
    }
    try {
      audio = await _scanAudio();
    } catch (error) {
      errors.add('audio scan: $error');
    }

    var videosSaved = 0;
    for (final item in videos) {
      if (!await _persist(item, HikmahMediaType.video, errors)) {
        continue;
      }
      videosSaved++;
    }

    var audioSaved = 0;
    for (final item in audio) {
      if (!await _persist(item, HikmahMediaType.audio, errors)) {
        continue;
      }
      audioSaved++;
    }

    final result =
        MediaScanResult(videosFound: videosSaved, audioFound: audioSaved, errors: errors);
    if (result.hasErrors) {
      debugPrint('MediaScanService: ${result.toString()}');
      for (final error in errors) {
        debugPrint('MediaScanService: $error');
      }
    }
    return result;
  }

  Future<bool> _persist(
    ScannedMedia item,
    HikmahMediaType type,
    List<String> errors,
  ) async {
    try {
      final existing = await media.byPath(item.uri);
      final companion = companionFromScanned(
        item,
        type: type,
        existing: existing,
      );
      await media.upsert(companion);
      return true;
    } catch (error, stackTrace) {
      errors.add('${item.uri}: $error');
      debugPrint('MediaScanService: failed to index ${item.uri}\n$error\n$stackTrace');
      return false;
    }
  }

  /// Maps a [ScannedMedia] entry onto a drift row for upserting.
  ///
  /// Exposed as a pure static for direct unit testing.
  static MediaItemsCompanion companionFromScanned(
    ScannedMedia item, {
    required HikmahMediaType type,
    MediaItem? existing,
  }) {
    final now = DateTime.now();
    final isNew = existing == null;
    return MediaItemsCompanion(
      id: Value(stableId(item.uri)),
      filePath: Value(item.uri),
      fileName: Value(item.fileName?.isNotEmpty == true
          ? item.fileName!
          : _fileNameFrom(item.uri)),
      title: Value(item.title?.isNotEmpty == true ? item.title! : null),
      mediaType: Value(type.value),
      durationMs: Value(item.durationMs ?? 0),
      fileSize: Value(item.size ?? 0),
      format: Value(item.mimeType),
      width: Value(item.width),
      height: Value(item.height),
      artist: Value(item.artist),
      album: Value(item.album),
      thumbnailPath: const Value.absent(),
      folderPath: Value(item.folderPath?.isNotEmpty == true
          ? item.folderPath!
          : '/'),
      folderName: Value(item.folderName?.isNotEmpty == true
          ? item.folderName!
          : item.folderPath),
      dateAdded: isNew
          ? Value((item.dateAdded ?? now).millisecondsSinceEpoch)
          : Value(existing.dateAdded),
      dateModified: Value(item.dateModified?.millisecondsSinceEpoch),
      lastPlayed: isNew ? const Value.absent() : Value(existing.lastPlayed),
      playCount: isNew ? const Value.absent() : Value(existing.playCount),
      lastPosition: isNew ? const Value.absent() : Value(existing.lastPosition),
      updatedAt: Value(now.millisecondsSinceEpoch),
    );
  }

  /// Stable library id for a media location (content URI).
  static String stableId(String uri) {
    final digest = sha256.convert(utf8.encode(uri)).toString();
    return 'media-${digest.substring(0, 16)}';
  }

  static String _fileNameFrom(String uri) {
    final withoutQuery = uri.split('?').first;
    final segments = withoutQuery.split('/');
    return segments.isEmpty ? uri : segments.last;
  }
}