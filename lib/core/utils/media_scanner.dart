import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../platform/platform_channels.dart';

/// A single media entry discovered on the device by [MediaScanner].
///
/// Carries the native MediaStore metadata; the scan service maps this onto
/// the persisted library row (drift `MediaItems`).
class ScannedMedia {
  const ScannedMedia({
    required this.id,
    required this.uri,
    this.fileName,
    this.title,
    this.mimeType,
    this.size,
    this.durationMs,
    this.width,
    this.height,
    this.folderPath,
    this.folderName,
    this.artist,
    this.album,
    this.dateAdded,
    this.dateModified,
  });

  /// MediaStore row id (its own `_ID`), useful for thumbnails later.
  final String id;

  /// Playable location — an Android `content://` URI.
  final String uri;

  final String? fileName;
  final String? title;
  final String? mimeType;
  final int? size;
  final int? durationMs;
  final int? width;
  final int? height;

  /// Folder path the file lives in (MediaStore relative path, or parent dir).
  final String? folderPath;
  final String? folderName;

  final String? artist;
  final String? album;

  final DateTime? dateAdded;
  final DateTime? dateModified;

  /// Best human-readable name for this item.
  String get displayTitle {
    final t = title;
    if (t != null && t.isNotEmpty) return t;
    final f = fileName;
    if (f != null && f.isNotEmpty) return f;
    return uri;
  }

  factory ScannedMedia.fromJson(Map<String, dynamic> json) {
    DateTime? added;
    final addedMs = json['dateAdded'];
    if (addedMs is int && addedMs > 0) {
      added = DateTime.fromMillisecondsSinceEpoch(addedMs);
    }
    DateTime? modified;
    final modifiedMs = json['dateModified'];
    if (modifiedMs is int && modifiedMs > 0) {
      modified = DateTime.fromMillisecondsSinceEpoch(modifiedMs);
    }
    return ScannedMedia(
      id: json['id'] as String? ?? '',
      uri: json['uri'] as String? ?? '',
      fileName: json['fileName'] as String?,
      title: json['title'] as String?,
      mimeType: json['mimeType'] as String?,
      size: json['size'] as int?,
      durationMs: json['durationMs'] as int?,
      width: json['width'] as int?,
      height: json['height'] as int?,
      folderPath: json['folderPath'] as String?,
      folderName: json['folderName'] as String?,
      artist: json['artist'] as String?,
      album: json['album'] as String?,
      dateAdded: added,
      dateModified: modified,
    );
  }

  @override
  String toString() => 'ScannedMedia(${fileName ?? title}) @ $uri';
}

/// Discovers on-device videos and audio through the [PlatformChannels]
/// MediaStore bridge.
///
/// This is the Dart half of the native `com.hikmahplayer/media_scanner`
/// method channel implemented in `MainActivity.kt`. On non-Android platforms
/// the scan is a no-op returning an empty list, so library screens stay safe
/// in tests and on desktop.
class MediaScanner {
  const MediaScanner._();

  static const _scanChannel = PlatformChannels.mediaScanner;

  /// Lists every video the current permissions expose.
  static Future<List<ScannedMedia>> scanForVideos({
    String? directoryPath,
  }) =>
      _scan('scanVideos', directoryPath);

  /// Lists every audio track the current permissions expose.
  static Future<List<ScannedMedia>> scanForAudio({
    String? directoryPath,
  }) =>
      _scan('scanAudio', directoryPath);

  static Future<List<ScannedMedia>> _scan(
    String method,
    String? directoryPath,
  ) async {
    if (!Platform.isAndroid) return const [];
    try {
      final arguments = directoryPath == null ? null : {'directoryPath': directoryPath};
      final raw =
          await _scanChannel.invokeListMethod<dynamic>(method, arguments);
      if (raw == null) return const [];
      return [
        for (final entry in raw)
          if (entry is Map)
            ScannedMedia.fromJson(entry.cast<String, dynamic>()),
      ];
    } on MissingPluginException catch (error) {
      // Native bridge absent (partial desktop build, unusual device): return
      // nothing instead of crashing the scan screen.
      debugPrint('MediaScanner: $error');
      return const [];
    } on PlatformException catch (error) {
      debugPrint('MediaScanner: $method failed: $error');
      return const [];
    }
  }

  /// Requests the runtime permissions the scanner needs.
  ///
  /// On Android 13+ this maps to READ_MEDIA_VIDEO / READ_MEDIA_AUDIO (and
  /// photos); permission_handler maps the same requests to
  /// READ_EXTERNAL_STORAGE on older versions. On Android 11+ it also asks for
  /// "All files access" ([Permission.manageExternalStorage]) so removable
  /// volumes (SD card, USB-OTG) become readable directly — that request opens
  /// the system settings page and counts as granted only if the user confirms.
  ///
  /// Returns whether at least one scan-capable grant was obtained: video,
  /// audio, or all-files access.
  static Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) return false;
    try {
      final level = await sdkInt();
      final results = await [
        if (level >= 33) ...[Permission.videos, Permission.audio, Permission.photos],
        if (level >= 30) Permission.manageExternalStorage,
        if (level < 33) Permission.storage,
      ].request();
      return (results[Permission.videos]?.isGranted ?? false) ||
          (results[Permission.audio]?.isGranted ?? false) ||
          (results[Permission.manageExternalStorage]?.isGranted ?? false) ||
          (results[Permission.storage]?.isGranted ?? false);
    } catch (error) {
      debugPrint('MediaScanner: permission request failed: $error');
      return false;
    }
  }

  /// The Android SDK API level (`Build.VERSION.SDK_INT`) reported by the
  /// native bridge, or `0` when unavailable (non-Android or bridge absent).
  ///
  /// Used by the onboarding permission flow to decide between the legacy
  /// `READ_EXTERNAL_STORAGE` request (Android < 13) and the granular
  /// `READ_MEDIA_*` requests (Android 13+).
  static Future<int> sdkInt() async {
    if (!Platform.isAndroid) return 0;
    try {
      return await _scanChannel.invokeMethod<int>('sdkInt') ?? 0;
    } catch (error) {
      debugPrint('MediaScanner: sdkInt failed: $error');
      return 0;
    }
  }

  /// Whether "All files access" (`MANAGE_EXTERNAL_STORAGE`, Android 11+) is
  /// granted. With it, the scanner enumerates every mounted volume directly —
  /// SD cards, USB-OTG drives and other removable storage — instead of only
  /// what MediaStore indexes. `false` on Android ≤ 10 and non-Android hosts.
  static Future<bool> hasAllFilesAccess() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _scanChannel.invokeMethod<bool>('allFilesAccess') ?? false;
    } catch (error) {
      debugPrint('MediaScanner: allFilesAccess failed: $error');
      return false;
    }
  }

  /// Opens the system "All files access" settings page (Android 11+) so the
  /// user can let the scanner read SD / USB / OTG storage. Best-effort; the
  /// scan falls back to MediaStore when the grant is refused.
  static Future<void> requestAllFilesAccess() async {
    if (!Platform.isAndroid) return;
    try {
      await _scanChannel.invokeMethod<void>('requestAllFilesAccess');
    } catch (error) {
      debugPrint('MediaScanner: requestAllFilesAccess failed: $error');
    }
  }

  /// Requests cancellation of an in-flight scan.
  static Future<void> cancelScan() async {
    if (!Platform.isAndroid) return;
    try {
      await _scanChannel.invokeMethod<void>('cancelScan');
    } catch (error) {
      debugPrint('MediaScanner: cancel failed: $error');
    }
  }
}