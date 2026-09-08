import 'package:flutter/material.dart';

/// Contextual app bar shown while multi-selecting songs.
class MusicSelectionAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MusicSelectionAppBar({
    super.key,
    required this.count,
    required this.total,
    this.onSelectAll,
    this.onClear,
    this.onDelete,
    this.onFavorite,
    this.onAddToQueue,
    this.onPlay,
  });

  final int count;
  final int total;
  final VoidCallback? onSelectAll;
  final VoidCallback? onClear;
  final VoidCallback? onDelete;
  final VoidCallback? onFavorite;
  final VoidCallback? onAddToQueue;
  final VoidCallback? onPlay;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close_rounded),
        tooltip: 'Clear selection',
        onPressed: onClear,
      ),
      title: Text(
        '$count selected',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      actions: [
        if (onSelectAll != null)
          TextButton(
            onPressed: count == total ? onClear : onSelectAll,
            child: Text(count == total ? 'Deselect all' : 'Select all'),
          ),
        if (onAddToQueue != null)
          IconButton(
            icon: const Icon(Icons.queue_music_rounded),
            tooltip: 'Add to queue',
            onPressed: onAddToQueue,
          ),
        if (onPlay != null)
          IconButton(
            icon: const Icon(Icons.play_arrow_rounded),
            tooltip: 'Play selected',
            onPressed: onPlay,
          ),
        if (onFavorite != null)
          IconButton(
            icon: const Icon(Icons.favorite_rounded),
            tooltip: 'Favorite selected',
            onPressed: onFavorite,
          ),
        if (onDelete != null)
          IconButton(
            icon: const Icon(Icons.delete_rounded),
            tooltip: 'Delete selected',
            onPressed: onDelete,
          ),
        const SizedBox(width: 8),
      ],
    );
  }
}