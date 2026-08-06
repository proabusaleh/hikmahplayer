/// State of a scanned library folder.
enum LibraryFolderStatus { idle, scanning, error }

/// A registered scan root: a local (or network-mounted) folder whose media is
/// indexed into the library.
///
/// All content found under [path] is scanned recursively by default, filtered
/// by [includeSubtitleFiles] and [ignorePatterns]. Items discovered are tagged
/// with this folder's id so they can be re-scanned and re-validated later.
class LibraryFolder {
  /// Stable identifier of this folder.
  final String id;

  /// Absolute path of the folder to scan.
  final String path;

  /// Optional display name shown in the library. Defaults to the folder name.
  final String? name;

  /// Whether this folder is actively scanned.
  final bool enabled;

  /// Whether sub-folders are scanned recursively.
  final bool recursive;

  /// Whether sidecar subtitle files are indexed as part of this folder.
  final bool includeSubtitleFiles;

  /// Glob-style patterns that exclude matching paths (applied to file names).
  final List<String> ignorePatterns;

  /// Whether the folder points at a network source (NAS/SMB/FTP/WebDAV/cloud).
  final bool isNetwork;

  /// When the folder was registered.
  final DateTime addedAt;

  /// When the folder was last scanned.
  final DateTime? lastScanAt;

  /// Number of media items currently indexed under this folder.
  final int itemCount;

  /// Current scanning status.
  final LibraryFolderStatus status;

  const LibraryFolder({
    required this.id,
    required this.path,
    this.name,
    this.enabled = true,
    this.recursive = true,
    this.includeSubtitleFiles = false,
    this.ignorePatterns = const [],
    this.isNetwork = false,
    required this.addedAt,
    this.lastScanAt,
    this.itemCount = 0,
    this.status = LibraryFolderStatus.idle,
  });

  LibraryFolder copyWith({
    String? id,
    String? path,
    String? name,
    bool clearName = false,
    bool? enabled,
    bool? recursive,
    bool? includeSubtitleFiles,
    List<String>? ignorePatterns,
    bool? isNetwork,
    DateTime? addedAt,
    DateTime? lastScanAt,
    int? itemCount,
    LibraryFolderStatus? status,
  }) {
    return LibraryFolder(
      id: id ?? this.id,
      path: path ?? this.path,
      name: clearName ? null : name ?? this.name,
      enabled: enabled ?? this.enabled,
      recursive: recursive ?? this.recursive,
      includeSubtitleFiles: includeSubtitleFiles ?? this.includeSubtitleFiles,
      ignorePatterns: ignorePatterns ?? this.ignorePatterns,
      isNetwork: isNetwork ?? this.isNetwork,
      addedAt: addedAt ?? this.addedAt,
      lastScanAt: lastScanAt ?? this.lastScanAt,
      itemCount: itemCount ?? this.itemCount,
      status: status ?? this.status,
    );
  }

  /// Display name of the folder, falling back to the last path segment.
  String get displayName {
    if (name != null && name!.isNotEmpty) return name!;
    final trimmed = path.replaceAll('\\', '/');
    final segments =
        trimmed.split('/').where((segment) => segment.isNotEmpty).toList();
    return segments.isEmpty ? path : segments.last;
  }

  @override
  bool operator ==(Object other) {
    return other is LibraryFolder && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'LibraryFolder(id: $id, path: $path, items: $itemCount)';
}
