import 'library_item.dart';

/// A set of library items that share identical content.
///
/// Detected by grouping items of the same file size and then comparing their
/// content hash — so duplicate detection is content-based, not filename-based
/// (section 3.1).
class DuplicateGroup {
  /// Stable identifier of this group.
  final String id;

  /// SHA-256 hash of the shared content.
  final String contentHash;

  /// Byte size shared by all members.
  final int fileSize;

  /// The items believed to be duplicates of each other.
  final List<LibraryItem> items;

  const DuplicateGroup({
    required this.id,
    required this.contentHash,
    required this.fileSize,
    required this.items,
  });

  /// The item most likely intended as the "keeper": highest play count, then
  /// earliest added.
  LibraryItem get primary {
    if (items.length == 1) return items.first;
    final sorted = [...items]..sort((a, b) {
        final byPlays = b.playCount.compareTo(a.playCount);
        if (byPlays != 0) return byPlays;
        final aAdded = a.media.dateAdded;
        final bAdded = b.media.dateAdded;
        if (aAdded != null && bAdded != null) return aAdded.compareTo(bAdded);
        return 0;
      });
    return sorted.first;
  }

  /// The duplicate members (everything except [primary]).
  List<LibraryItem> get duplicates {
    final primaryId = primary.id;
    return items.where((item) => item.id != primaryId).toList();
  }

  /// Formatted size of the duplicated content.
  String get formattedSize => _formatBytes(fileSize);

  static String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var value = bytes.toDouble();
    var index = 0;
    while (value >= 1024 && index < suffixes.length - 1) {
      value /= 1024;
      index++;
    }
    return '${value.toStringAsFixed(2)} ${suffixes[index]}';
  }

  @override
  String toString() =>
      'DuplicateGroup(${items.length} items, $formattedSize, ${contentHash.substring(0, 8)}…)';
}
