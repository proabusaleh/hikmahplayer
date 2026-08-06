import 'media_item.dart';

/// An ordered, in-memory list of media prepared for playback.
///
/// Unlike [Playlist] (which stores references by id), a [PlaybackQueue] holds
/// fully resolved [MediaItem]s so the player can start immediately without
/// hitting the library.
class PlaybackQueue {
  /// The media items to play, in order.
  final List<MediaItem> items;

  /// Index of the item that should be (or is) currently playing.
  final int currentIndex;

  /// Whether shuffle is enabled for this queue.
  final bool shuffle;

  const PlaybackQueue({
    this.items = const [],
    this.currentIndex = 0,
    this.shuffle = false,
  });

  /// An empty queue.
  static const PlaybackQueue empty = PlaybackQueue();

  /// A queue containing a single [item].
  PlaybackQueue.single(MediaItem item)
      : items = [item],
        currentIndex = 0,
        shuffle = false;

  /// Number of items in the queue.
  int get length => items.length;

  /// Whether the queue is empty.
  bool get isEmpty => items.isEmpty;

  /// The currently selected item, or `null` when the queue is empty.
  MediaItem? get current {
    if (isEmpty || currentIndex < 0 || currentIndex >= items.length) {
      return null;
    }
    return items[currentIndex];
  }

  PlaybackQueue copyWith({
    List<MediaItem>? items,
    int? currentIndex,
    bool? shuffle,
  }) {
    return PlaybackQueue(
      items: items ?? this.items,
      currentIndex: currentIndex ?? this.currentIndex,
      shuffle: shuffle ?? this.shuffle,
    );
  }

  @override
  String toString() =>
      'PlaybackQueue(length: ${items.length}, currentIndex: $currentIndex, shuffle: $shuffle)';
}
