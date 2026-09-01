import 'package:flutter/material.dart';

import '../../core/theme/app_dimensions.dart';
import '../../core/extensions/media_item_extensions.dart';
import '../../features/player/domain/models/media_item.dart';

class MediaOptionsSheet extends StatelessWidget {
  final MediaItem media;
  final VoidCallback? onPlay;
  final VoidCallback? onPlayNext;
  final VoidCallback? onAddToQueue;
  final VoidCallback? onAddToPlaylist;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onShare;
  final VoidCallback? onDetails;

  const MediaOptionsSheet({
    super.key,
    required this.media,
    this.onPlay,
    this.onPlayNext,
    this.onAddToQueue,
    this.onAddToPlaylist,
    this.onToggleFavorite,
    this.onShare,
    this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.md),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    media.isVideo ? Icons.movie : Icons.music_note,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        media.displayTitle,
                        style: theme.textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${media.format} \u2022 ${media.folderName}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          _ActionTile(icon: Icons.play_arrow, label: 'Play', onTap: onPlay),
          _ActionTile(
              icon: Icons.playlist_play, label: 'Play Next', onTap: onPlayNext),
          _ActionTile(
              icon: Icons.queue_music,
              label: 'Add to Queue',
              onTap: onAddToQueue),
          _ActionTile(
              icon: Icons.playlist_add,
              label: 'Add to Playlist',
              onTap: onAddToPlaylist),
          _ActionTile(
            icon: media.isFavorite ? Icons.favorite : Icons.favorite_border,
            label: media.isFavorite
                ? 'Remove from Favorites'
                : 'Add to Favorites',
            iconColor: media.isFavorite ? Colors.red : null,
            onTap: onToggleFavorite,
          ),
          _ActionTile(
              icon: Icons.share_outlined, label: 'Share', onTap: onShare),
          _ActionTile(
              icon: Icons.info_outline, label: 'Details', onTap: onDetails),
          const SizedBox(height: AppDimensions.sm),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;
  final VoidCallback? onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(label),
      onTap: onTap != null
          ? () {
              Navigator.pop(context);
              onTap?.call();
            }
          : null,
      enabled: onTap != null,
    );
  }
}
