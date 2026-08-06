import 'package:flutter/material.dart';

import '../../../../shared/utils/format.dart';
import '../../domain/models/library_item.dart';
import '../../../player/domain/models/media_item.dart';

/// Dense list row for a library item with a trailing action menu.
class MediaListTile extends StatelessWidget {
  const MediaListTile({
    super.key,
    required this.item,
    this.onTap,
    this.onPlay,
    this.trailing,
  });

  final LibraryItem item;
  final VoidCallback? onTap;
  final VoidCallback? onPlay;
  final List<PopupMenuEntry<String>>? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = item.media;
    return ListTile(
      onTap: onTap,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 48,
          height: 64,
          child: media.artworkUri != null
              ? Image.network(
                  media.artworkUri!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _placeholder(theme, media),
                )
              : _placeholder(theme, media),
        ),
      ),
      title: Text(media.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        _subtitle(media),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (media.duration != null)
            Text(
              Fmt.duration(media.duration),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          IconButton(
            tooltip: 'Play',
            icon: const Icon(Icons.play_circle_outline),
            onPressed: onPlay,
          ),
          if (trailing != null)
            PopupMenuButton<String>(
              itemBuilder: (context) => trailing!,
              onSelected: (_) {},
            ),
        ],
      ),
    );
  }

  String _subtitle(MediaItem media) {
    final parts = <String>[];
    if (media.type == MediaType.audio) {
      if (media.artist != null) parts.add(media.artist!);
      if (media.album != null) parts.add(media.album!);
    } else {
      if (media.year != null) parts.add(media.year.toString());
      if (media.width != null && media.height != null) {
        parts.add('${media.width}x${media.height}');
      }
      if (media.videoCodec != null) parts.add(media.videoCodec!);
    }
    if (media.fileSize != null) parts.add(Fmt.bytes(media.fileSize));
    return parts.join(' · ');
  }

  Widget _placeholder(ThemeData theme, MediaItem media) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        media.type == MediaType.audio ? Icons.music_note : Icons.movie,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
