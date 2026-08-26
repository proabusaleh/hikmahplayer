import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../../core/extensions/duration_extensions.dart';
import '../../../../../core/extensions/media_item_extensions.dart';
import '../../../../../core/theme/app_dimensions.dart';
import '../../../../../core/utils/file_size_formatter.dart';
import '../../../../../features/player/domain/models/media_item.dart';

class VideoTile extends StatelessWidget {
  final MediaItem video;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const VideoTile({
    super.key,
    required this.video,
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
        vertical: AppDimensions.xs,
      ),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 120,
          height: 68,
          child: Stack(
            fit: StackFit.expand,
            children: [
              video.thumbnailPath != null
                  ? Image.file(
                      File(video.thumbnailPath!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(theme),
                    )
                  : _placeholder(theme),
              Positioned(
                right: 4,
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    video.safeDuration.formatted,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              if (video.hasResumePosition)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: LinearProgressIndicator(
                    value: video.progressPercent,
                    minHeight: 2,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation(
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      title: Text(
        video.displayTitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Text(
              FileSizeFormatter.format(video.safeFileSize),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(width: 6),
            Text('\u2022', style: theme.textTheme.bodySmall),
            const SizedBox(width: 6),
            Text(
              video.format,
              style: theme.textTheme.bodySmall,
            ),
            if (video.resolution.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text('\u2022', style: theme.textTheme.bodySmall),
              const SizedBox(width: 6),
              Text(
                video.resolution,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, size: 20),
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'play', child: Text('Play')),
          const PopupMenuItem(value: 'queue', child: Text('Add to Queue')),
          const PopupMenuItem(
              value: 'playlist', child: Text('Add to Playlist')),
          const PopupMenuItem(value: 'favorite', child: Text('Favorite')),
          const PopupMenuItem(value: 'info', child: Text('Details')),
        ],
        onSelected: (value) {},
      ),
    );
  }

  Widget _placeholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.movie_creation_outlined,
          size: 24,
          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
        ),
      ),
    );
  }
}
