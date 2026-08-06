import 'package:flutter/material.dart';

import '../../../../shared/utils/format.dart';
import '../../domain/models/library_item.dart';
import '../../../player/domain/models/media_item.dart';

/// Tappable grid cell for a library item with poster/artwork and title.
class MediaGrid extends StatelessWidget {
  const MediaGrid({
    super.key,
    required this.items,
    this.onTap,
    this.onLongPress,
    this.itemExtent = 160,
  });

  final List<LibraryItem> items;
  final void Function(LibraryItem item)? onTap;
  final void Function(LibraryItem item)? onLongPress;
  final double itemExtent;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisExtent: itemExtent,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _MediaGridCell(
          item: item,
          onTap: onTap == null ? null : () => onTap!(item),
          onLongPress: onLongPress == null ? null : () => onLongPress!(item),
        );
      },
    );
  }
}

class _MediaGridCell extends StatelessWidget {
  const _MediaGridCell({required this.item, this.onTap, this.onLongPress});

  final LibraryItem item;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = item.media;
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (media.artworkUri != null)
                    Image.network(
                      media.artworkUri!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _placeholder(theme, media),
                    )
                  else
                    _placeholder(theme, media),
                  if (media.duration != null)
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          Fmt.duration(media.duration),
                          style: const TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ),
                    ),
                  if (media.type == MediaType.audio)
                    Positioned(
                      left: 6,
                      top: 6,
                      child: const Icon(Icons.music_note, color: Colors.white70, size: 18),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            media.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          Text(
            media.type == MediaType.audio
                ? (media.artist ?? 'Audio')
                : (media.year?.toString() ?? 'Video'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(ThemeData theme, MediaItem media) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        media.type == MediaType.audio ? Icons.music_note : Icons.movie,
        size: 40,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
