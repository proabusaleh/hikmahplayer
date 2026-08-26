import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../../core/extensions/duration_extensions.dart';
import '../../../../../core/extensions/media_item_extensions.dart';
import '../../../../../core/theme/app_dimensions.dart';
import '../../../../../features/player/domain/models/media_item.dart';

class SongTile extends StatelessWidget {
  final MediaItem song;
  final int trackNumber;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const SongTile({
    super.key,
    required this.song,
    required this.trackNumber,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      onLongPress: onLongPress,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.md,
        vertical: 2,
      ),
      leading: _buildThumbnail(theme),
      title: Text(
        song.displayTitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        song.artist ?? 'Unknown Artist',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (song.isFavorite)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                Icons.favorite,
                size: 16,
                color: Colors.red.shade400,
              ),
            ),
          Text(
            song.safeDuration.formatted,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.more_vert,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(ThemeData theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: AppDimensions.audioThumbSize,
        height: AppDimensions.audioThumbSize,
        child: song.albumArtPath != null
            ? Image.file(
                File(song.albumArtPath!),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _defaultArt(theme),
              )
            : _defaultArt(theme),
      ),
    );
  }

  Widget _defaultArt(ThemeData theme) {
    return Container(
      color: theme.colorScheme.primaryContainer,
      child: Icon(
        Icons.music_note,
        color: theme.colorScheme.onPrimaryContainer,
        size: 24,
      ),
    );
  }
}
