import 'package:hikmahplayer/features/library/domain/models/library_folder.dart';

/// A single problem encountered while scanning a folder.
class ScanError {
  /// The path of the file/folder that could not be processed.
  final String path;

  /// Human readable description of the failure.
  final String message;

  const ScanError({required this.path, required this.message});

  Map<String, dynamic> toJson() => {'path': path, 'message': message};

  factory ScanError.fromJson(Map<String, dynamic> json) => ScanError(
        path: json['path'] as String,
        message: json['message'] as String,
      );

  @override
  String toString() => 'ScanError(path: $path, message: $message)';
}

/// The outcome of a [LibraryFolder] scan.
class ScanResult {
  /// Folder that was scanned.
  final LibraryFolder folder;

  /// When the scan finished.
  final DateTime scannedAt;

  /// Total media files discovered on disk.
  final int discovered;

  /// Files that were new and added to the index.
  final int added;

  /// Files already indexed whose metadata was refreshed.
  final int updated;

  /// Previously indexed files that were no longer present.
  final int removed;

  /// Errors encountered while scanning.
  final List<ScanError> errors;

  /// How long the scan took.
  final Duration elapsed;

  const ScanResult({
    required this.folder,
    required this.scannedAt,
    this.discovered = 0,
    this.added = 0,
    this.updated = 0,
    this.removed = 0,
    this.errors = const [],
    this.elapsed = Duration.zero,
  });

  ScanResult copyWith({
    LibraryFolder? folder,
    DateTime? scannedAt,
    int? discovered,
    int? added,
    int? updated,
    int? removed,
    List<ScanError>? errors,
    Duration? elapsed,
  }) {
    return ScanResult(
      folder: folder ?? this.folder,
      scannedAt: scannedAt ?? this.scannedAt,
      discovered: discovered ?? this.discovered,
      added: added ?? this.added,
      updated: updated ?? this.updated,
      removed: removed ?? this.removed,
      errors: errors ?? this.errors,
      elapsed: elapsed ?? this.elapsed,
    );
  }

  Map<String, dynamic> toJson() => {
        'folder': folder.id,
        'scannedAt': scannedAt.toIso8601String(),
        'discovered': discovered,
        'added': added,
        'updated': updated,
        'removed': removed,
        'errors': errors.map((e) => e.toJson()).toList(),
        'elapsed': elapsed.inMilliseconds,
      };

  @override
  String toString() =>
      'ScanResult(${folder.path}: +$added ~$updated -$removed, errors: ${errors.length})';
}
