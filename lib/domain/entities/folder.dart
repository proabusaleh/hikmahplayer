class Folder {
  const Folder({
    required this.path,
    required this.mediaCount,
    this.thumbnailMediaId,
  });

  final String path;
  final int mediaCount;
  final String? thumbnailMediaId;

  String get name => path.split('/').last;

  Folder copyWith({
    String? path,
    int? mediaCount,
    String? thumbnailMediaId,
  }) {
    return Folder(
      path: path ?? this.path,
      mediaCount: mediaCount ?? this.mediaCount,
      thumbnailMediaId: thumbnailMediaId ?? this.thumbnailMediaId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Folder && other.path == path;

  @override
  int get hashCode => path.hashCode;
}
