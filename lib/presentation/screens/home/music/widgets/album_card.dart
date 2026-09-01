import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../../core/extensions/duration_extensions.dart';
import '../../../../../core/extensions/media_item_extensions.dart';
import '../../../../../core/theme/app_dimensions.dart';
import '../../../../../features/player/domain/models/media_item.dart';

class AlbumCard extends StatelessWidget {
  final String albumName;
  final List<MediaItem> songs;
  final VoidCallback onTap;

  const AlbumCard({
    super.key,
    required this.albumName,
    required this.songs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalDuration = songs.fold<Duration>(
      Duration.zero,
      (sum, s) => sum + s.safeDuration,
    );
    final firstArt = songs
        .where((s) => s.albumArtPath != null)
        .map((s) => s.albumArtPath!)
        .firstOrNull;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              child: firstArt != null
                  ? Image.file(
                      File(firstArt),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _defaultArt(theme),
                    )
                  : _defaultArt(theme),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            albumName,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${songs.length} songs \u2022 ${totalDuration.compact}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _defaultArt(ThemeData theme) {
    return Container(
      color: theme.colorScheme.primaryContainer,
      child: Center(
        child: Icon(
          Icons.album_outlined,
          size: 48,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
