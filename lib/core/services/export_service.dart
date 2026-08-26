import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../features/creative/domain/models/annotation.dart';
import '../../features/creative/domain/models/clip.dart';
import '../../features/creative/domain/models/clip_collection.dart';
import '../../features/creative/domain/models/export_format.dart';
import '../../features/creative/domain/models/export_job.dart';
import '../../features/creative/domain/models/trim_range.dart';
import '../../features/player/domain/models/media_item.dart';
import '../utils/ffmpeg_command_builder.dart';
import 'export_backend.dart';

/// Orchestrates ffmpeg exports and manages the library of created clips.
///
/// Every export runs as a background job (see [ExportJob]) and publishes the
/// latest job on [activeJob]. Successful clip creations are recorded in
/// [clips]; collections let users organise them.
///
/// The service is pure Flutter/Dart: the actual ffmpeg invocation is delegated
/// to an [ExportBackend] (system binary on desktop, ffmpeg-kit on mobile).
class ExportService extends ChangeNotifier {
  final ExportBackend _backend;
  final Future<String> Function() _outputDirectoryProvider;
  final String Function(String hint) _idGenerator;

  /// Latest export job (running or finished).
  final ValueNotifier<ExportJob?> activeJob = ValueNotifier<ExportJob?>(null);

  /// Created clips, newest first.
  final ValueNotifier<List<Clip>> clips = ValueNotifier<List<Clip>>([]);

  /// User and system clip collections.
  final ValueNotifier<List<ClipCollection>> collections =
      ValueNotifier<List<ClipCollection>>([]);

  /// Recently finished jobs, newest first (kept for a debug/history UI).
  final List<ExportJob> jobHistory = [];

  /// Maximum number of [jobHistory] entries kept.
  static const int maxJobHistory = 20;

  /// Id of the built-in favourites collection.
  static const String favouritesCollectionId = 'favourites';

  ExportService({
    ExportBackend? backend,
    Future<String> Function()? outputDirectoryProvider,
    String Function(String hint)? idGenerator,
  })  : _backend = backend ?? ExportService.defaultBackend(),
        _outputDirectoryProvider =
            outputDirectoryProvider ?? _defaultOutputDirectory,
        _idGenerator = idGenerator ?? _defaultIdGenerator {
    collections.value = [
      ClipCollection(
        id: favouritesCollectionId,
        name: 'Favourites',
        isSystem: true,
        createdAt: DateTime.now(),
      ),
    ];
  }

  static ExportBackend defaultBackend() => ProcessExportBackend();

  static Future<String> _defaultOutputDirectory() async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      return p.join(docs.path, 'HikmahPlayer', 'Exports');
    } catch (_) {
      return p.join(Directory.systemTemp.path, 'hikmahplayer_exports');
    }
  }

  static String _defaultIdGenerator(String hint) =>
      '${hint}_${DateTime.now().microsecondsSinceEpoch}';

  // ---------------------------------------------------------------------
  // Clip creation
  // ---------------------------------------------------------------------

  /// Cuts [range] out of [source] and exports it as a standalone clip.
  ///
  /// On success a [Clip] record is added to [clips]. [expectedDuration] lets
  /// callers supply the source's full length so progress reflects the segment;
  /// when omitted, [range.duration] is used.
  Future<ExportJob> createClip({
    required MediaItem source,
    required TrimRange range,
    ExportPreset preset = ExportPreset.mp4H264,
    String? title,
    List<String> tags = const [],
    List<Annotation> annotations = const [],
    String? caption,
  }) async {
    final mediaDuration = source.duration;
    final trimmed = mediaDuration == null ? range : range.clampTo(mediaDuration);
    if (!trimmed.isValid) {
      throw ArgumentError('Invalid clip range: $range');
    }

    final stem = (title ?? source.title).trim().isEmpty
        ? 'clip'
        : _sanitiseName(title ?? source.title);
    final outputPath = await _outputPath('clips', stem, preset.extension);

    final args = FFmpegCommandBuilder.trim(
      sourcePath: source.uri,
      outputPath: outputPath,
      range: trimmed,
      copyStreams: false,
      preset: preset,
    );

    final job = await _runJob(
      ExportKind.clip,
      source.uri,
      outputPath,
      args,
      expectedDuration: trimmed.duration,
    );

    if (job.status == ExportStatus.succeeded) {
      final clip = Clip(
        id: _idGenerator('clip'),
        sourceMediaId: source.id,
        title: title ?? source.title,
        sourcePath: source.uri,
        outputPath: outputPath,
        range: trimmed,
        presetJson: preset.toJson(),
        annotations: annotations,
        caption: caption,
        tags: tags,
        createdAt: DateTime.now(),
      );
      clips.value = [clip, ...clips.value];
      notifyListeners();
    }
    return job;
  }

  /// Renames the title of an existing [Clip].
  void renameClip(String clipId, String newTitle) {
    clips.value = [
      for (final c in clips.value)
        if (c.id == clipId) c.copyWith(title: newTitle) else c,
    ];
    notifyListeners();
  }

  /// Sets the caption of an existing [Clip].
  void updateCaption(String clipId, String? caption) {
    clips.value = [
      for (final c in clips.value)
        if (c.id == clipId) c.copyWith(caption: caption) else c,
    ];
    notifyListeners();
  }

  void addTag(String clipId, String tag) {
    final tagTrimmed = tag.trim();
    if (tagTrimmed.isEmpty) return;
    clips.value = [
      for (final c in clips.value)
        if (c.id == clipId && !c.tags.contains(tagTrimmed))
          c.copyWith(tags: [...c.tags, tagTrimmed])
        else
          c,
    ];
    notifyListeners();
  }

  void removeTag(String clipId, String tag) {
    clips.value = [
      for (final c in clips.value)
        if (c.id == clipId)
          c.copyWith(tags: c.tags.where((t) => t != tag).toList())
        else
          c,
    ];
    notifyListeners();
  }

  /// Deletes a clip record. The exported file is removed from disk too.
  Future<void> removeClip(String clipId) async {
    final clip = clips.value.cast<Clip?>().firstWhere(
          (c) => c?.id == clipId,
          orElse: () => null,
        );
    if (clip == null) return;
    clips.value = clips.value.where((c) => c.id != clipId).toList();
    collections.value = [
      for (final col in collections.value) col.withoutClip(clipId),
    ];
    notifyListeners();
    try {
      final file = File(clip.outputPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Best-effort: file may already be gone or locked.
    }
  }

  // ---------------------------------------------------------------------
  // Clip search / organisation
  // ---------------------------------------------------------------------

  /// Returns clips matching [query] against title, caption and tags.
  List<Clip> searchClips(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return List.unmodifiable(clips.value);
    return clips.value.where((c) => c.matches(q)).toList();
  }

  /// Returns clips tagged with every one of [tags].
  List<Clip> clipsWithAllTags(List<String> tags) {
    return clips.value
        .where((c) => tags.every(c.tags.contains))
        .toList();
  }

  ClipCollection? collectionById(String id) {
    for (final col in collections.value) {
      if (col.id == id) return col;
    }
    return null;
  }

  ClipCollection createCollection(String name, {String? description}) {
    final collection = ClipCollection(
      id: _idGenerator('collection'),
      name: name,
      description: description,
      createdAt: DateTime.now(),
    );
    collections.value = [...collections.value, collection];
    notifyListeners();
    return collection;
  }

  void renameCollection(String collectionId, String newName) {
    collections.value = [
      for (final col in collections.value)
        if (col.id == collectionId && !col.isSystem)
          col.copyWith(name: newName)
        else
          col,
    ];
    notifyListeners();
  }

  void deleteCollection(String collectionId) {
    final col = collectionById(collectionId);
    if (col == null || col.isSystem) return;
    collections.value = collections.value
        .where((c) => c.id != collectionId)
        .map((c) => c.copyWith(
              childCollectionIds: c.childCollectionIds
                  .where((id) => id != collectionId)
                  .toList(),
            ))
        .toList();
    notifyListeners();
  }

  void addClipToCollection(String collectionId, String clipId) {
    collections.value = [
      for (final col in collections.value)
        if (col.id == collectionId) col.withClip(clipId) else col,
    ];
    notifyListeners();
  }

  void removeClipFromCollection(String collectionId, String clipId) {
    collections.value = [
      for (final col in collections.value)
        if (col.id == collectionId) col.withoutClip(clipId) else col,
    ];
    notifyListeners();
  }

  /// Whether every clip id in [collectionId] still exists on disk.
  Future<Map<String, bool>> clipExistence(ClipCollection collection) async {
    final result = <String, bool>{};
    for (final id in collection.clipIds) {
      final clip = clips.value.cast<Clip?>().firstWhere(
            (c) => c?.id == id,
            orElse: () => null,
          );
      if (clip == null) {
        result[id] = false;
        continue;
      }
      result[id] = await File(clip.outputPath).exists();
    }
    return result;
  }

  // ---------------------------------------------------------------------
  // Generic exports (do not create [Clip] records)
  // ---------------------------------------------------------------------

  /// Converts [sourcePath] to a different format/preset.
  Future<ExportJob> convertFile({
    required String sourcePath,
    String? outputPath,
    ExportPreset preset = ExportPreset.mp4H264,
    Duration? expectedDuration,
  }) async {
    final out = outputPath ??
        await _outputPath(
            'converted', _stem(sourcePath), preset.extension);
    final args = FFmpegCommandBuilder.convert(
      sourcePath: sourcePath,
      outputPath: out,
      preset: preset,
    );
    return _runJob(ExportKind.convert, sourcePath, out, args,
        expectedDuration: expectedDuration);
  }

  /// Exports an animated GIF of [sourcePath].
  Future<ExportJob> exportGif({
    required String sourcePath,
    TrimRange? range,
    ExportPreset preset = ExportPreset.gifHigh,
    int width = 480,
    int height = 270,
    Duration? expectedDuration,
  }) async {
    final out =
        await _outputPath('gifs', _stem(sourcePath), 'gif');
    final args = FFmpegCommandBuilder.gif(
      sourcePath: sourcePath,
      outputPath: out,
      range: range,
      preset: preset,
      width: width,
      height: height,
    );
    return _runJob(ExportKind.gif, sourcePath, out, args,
        expectedDuration: expectedDuration);
  }

  /// Extracts the audio track of [sourcePath].
  Future<ExportJob> extractAudio({
    required String sourcePath,
    TrimRange? range,
    ExportPreset preset = ExportPreset.audioMp3,
    Duration? expectedDuration,
  }) async {
    final out = await _outputPath(
        'audio', _stem(sourcePath), preset.extension);
    final args = FFmpegCommandBuilder.extractAudio(
      sourcePath: sourcePath,
      outputPath: out,
      preset: preset,
      range: range,
    );
    return _runJob(ExportKind.audioExtract, sourcePath, out, args,
        expectedDuration: expectedDuration);
  }

  /// Extracts a sequence of still frames from [sourcePath].
  Future<ExportJob> extractFrames({
    required String sourcePath,
    String? outputDirectory,
    Duration? start,
    int? count,
    double frameRate = 1.0,
    int? width,
  }) async {
    final out = outputDirectory ??
        await _outputDirectoryProvider();
    final baseDir = await _ensureDirectory(out);
    final pattern = p.join(baseDir.path, '${_stem(sourcePath)}_%04d.jpg');
    final args = FFmpegCommandBuilder.extractFrames(
      sourcePath: sourcePath,
      outputPattern: pattern,
      start: start,
      count: count,
      frameRate: frameRate,
      width: width,
    );
    return _runJob(ExportKind.frames, sourcePath, pattern, args,
        expectedDuration: null);
  }

  /// Captures a single still frame at [at] into an image file.
  Future<ExportJob> captureFrame({
    required String sourcePath,
    required Duration at,
    String? outputPath,
    int? width,
    int quality = 2,
  }) async {
    final out = outputPath ??
        await _outputPath('frames', '${_stem(sourcePath)}_${at.inMilliseconds}',
            'jpg');
    final args = FFmpegCommandBuilder.singleFrame(
      sourcePath: sourcePath,
      outputPath: out,
      at: at,
      width: width,
      quality: quality,
    );
    return _runJob(ExportKind.singleFrame, sourcePath, out, args,
        expectedDuration: null);
  }

  /// Concatenates [inputPaths] (in order) into a single video.
  Future<ExportJob> mergeFiles({
    required List<String> inputPaths,
    String? outputPath,
    bool reencode = true,
    Duration? expectedDuration,
  }) async {
    if (inputPaths.isEmpty) {
      throw ArgumentError('mergeFiles requires at least one input');
    }
    final out = outputPath ??
        await _outputPath('merged', 'merge', 'mp4');
    final args = FFmpegCommandBuilder.merge(
      inputPaths: inputPaths,
      outputPath: out,
      reencode: reencode,
    );
    return _runJob(ExportKind.merge, inputPaths.first, out, args,
        expectedDuration: expectedDuration);
  }

  /// Speeds up ([factor] > 1) or slows down ([factor] < 1) [sourcePath].
  Future<ExportJob> speedChange({
    required String sourcePath,
    required double factor,
    String? outputPath,
    Duration? expectedDuration,
  }) async {
    final out = outputPath ??
        await _outputPath('speed', '${_stem(sourcePath)}_x$factor', 'mp4');
    final args = FFmpegCommandBuilder.speed(
      sourcePath: sourcePath,
      outputPath: out,
      factor: factor,
    );
    return _runJob(ExportKind.speed, sourcePath, out, args,
        expectedDuration: expectedDuration);
  }

  /// Burns [subtitlePath] into [sourcePath].
  Future<ExportJob> burnSubtitlesInto({
    required String sourcePath,
    required String subtitlePath,
    String? outputPath,
    double fontSize = 24,
    int? width,
    int? height,
    Duration? expectedDuration,
  }) async {
    final out = outputPath ??
        await _outputPath('subtitled', '${_stem(sourcePath)}_subs', 'mp4');
    final args = FFmpegCommandBuilder.burnSubtitles(
      sourcePath: sourcePath,
      outputPath: out,
      subtitlePath: subtitlePath,
      fontSize: fontSize,
      width: width,
      height: height,
    );
    return _runJob(ExportKind.burnSubtitles, sourcePath, out, args,
        expectedDuration: expectedDuration);
  }

  // ---------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------

  Future<ExportJob> _runJob(
    ExportKind kind,
    String inputPath,
    String outputPath,
    List<String> args, {
    Duration? expectedDuration,
  }) async {
    final job = ExportJob(
      id: _idGenerator('job'),
      kind: kind,
      inputPath: inputPath,
      outputPath: outputPath,
      status: ExportStatus.running,
      progress: 0,
      args: args,
      startedAt: DateTime.now(),
    );
    activeJob.value = job;
    notifyListeners();

    var running = job;
    ExportJob finished;
    try {
      final result = await _backend.run(
        args,
        expectedDuration: expectedDuration,
        onProgress: (progress) {
          running = running.copyWith(progress: progress);
          activeJob.value = running;
          notifyListeners();
        },
      );
      finished = running.copyWith(
        status:
            result.success ? ExportStatus.succeeded : ExportStatus.failed,
        error:
            result.success ? null : 'FFmpeg exited with code ${result.exitCode}',
        progress: result.success ? 1.0 : running.progress,
        finishedAt: DateTime.now(),
      );
    } catch (e) {
      finished = running.copyWith(
        status: ExportStatus.failed,
        error: e.toString(),
        finishedAt: DateTime.now(),
      );
    }

    jobHistory.insert(0, finished);
    if (jobHistory.length > maxJobHistory) {
      jobHistory.removeRange(maxJobHistory, jobHistory.length);
    }
    activeJob.value = finished;
    notifyListeners();
    return finished;
  }

  Future<Directory> _ensureDirectory(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<String> _outputPath(String subdir, String stem, String ext) async {
    final base = await _outputDirectoryProvider();
    final dir = await _ensureDirectory(p.join(base, subdir));
    final stamp = DateTime.now().millisecondsSinceEpoch;
    return p.join(dir.path, '${_sanitiseName(stem)}_$stamp.$ext');
  }

  static String _stem(String path) {
    final name = p.basenameWithoutExtension(path);
    return name.isEmpty ? 'export' : name;
  }

  static String _sanitiseName(String name) {
    final cleaned = name
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .trim();
    return cleaned.isEmpty ? 'export' : cleaned;
  }

  @override
  void dispose() {
    activeJob.dispose();
    clips.dispose();
    collections.dispose();
    super.dispose();
  }
}
