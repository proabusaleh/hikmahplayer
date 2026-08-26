class Folder {
  final String id;
  final String path;
  final String name;
  final int mediaCount;
  final DateTime createdAt;
  final bool isPinned;

  const Folder({
    required this.id,
    required this.path,
    required this.name,
    required this.mediaCount,
    required this.createdAt,
    this.isPinned = false,
  });
}
