import 'package:flutter/material.dart';

import '../../../../core/extensions/duration_extensions.dart';
import '../../../../core/storage/repositories/media_repository.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/utils/file_size_formatter.dart';
import '../../../providers/library_provider.dart' show MediaItemDisplay;
import '../shared/library_thumbnail.dart';
import 'video_library_provider.dart';

/// Renders the videos library in one of several view modes, honoring the
/// current selection state. Callers supply the list and selection callbacks so
/// this stays a pure presentational widget.
class VideoListRenderer extends StatelessWidget {
  const VideoListRenderer({
    super.key,
    required this.videos,
    required this.viewMode,
    required this.selectedIds,
    this.onPlayAt,
    this.onToggleSelection,
    this.onLongPress,
    this.onOpenActions,
  });

  final List<MediaItem> videos;
  final VideoLibraryViewMode viewMode;
  final Set<String> selectedIds;
  final ValueChanged<int>? onPlayAt;
  final ValueChanged<MediaItem>? onToggleSelection;
  final ValueChanged<MediaItem>? onLongPress;
  final ValueChanged<MediaItem>? onOpenActions;

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) return const SizedBox.shrink();
    final selectionActive = selectedIds.isNotEmpty;
    return switch (viewMode) {
      VideoLibraryViewMode.list =>
        _VideoListMode(videos: videos, selectionActive: selectionActive, selectedIds: selectedIds, onPlayAt: onPlayAt, onToggleSelection: onToggleSelection, onLongPress: onLongPress, onOpenActions: onOpenActions),
      VideoLibraryViewMode.grid =>
        _VideoGridMode(videos: videos, selectionActive: selectionActive, selectedIds: selectedIds, onPlayAt: onPlayAt, onToggleSelection: onToggleSelection, onLongPress: onLongPress, onOpenActions: onOpenActions),
      VideoLibraryViewMode.large =>
        _VideoLargeMode(videos: videos, selectionActive: selectionActive, selectedIds: selectedIds, onPlayAt: onPlayAt, onToggleSelection: onToggleSelection, onLongPress: onLongPress, onOpenActions: onOpenActions),
      VideoLibraryViewMode.gridComfortable =>
        _VideoComfortableGridMode(videos: videos, selectionActive: selectionActive, selectedIds: selectedIds, onPlayAt: onPlayAt, onToggleSelection: onToggleSelection, onLongPress: onLongPress, onOpenActions: onOpenActions),
      VideoLibraryViewMode.compact =>
        _VideoCompactMode(videos: videos, selectionActive: selectionActive, selectedIds: selectedIds, onPlayAt: onPlayAt, onToggleSelection: onToggleSelection, onLongPress: onLongPress, onOpenActions: onOpenActions),
    };
  }
}

/// Common tap/long-press behavior shared by every tile variant. When a
/// selection is active a tap toggles the row; otherwise it plays.
typedef TileCallbacks = ({
  Set<String> selectedIds,
  ValueChanged<int>? onPlayAt,
  ValueChanged<MediaItem>? onToggleSelection,
  ValueChanged<MediaItem>? onLongPress,
  ValueChanged<MediaItem>? onOpenActions,
});

class _TileBase extends StatelessWidget {
  const _TileBase({
    required this.media,
    required this.index,
    required this.callbacks,
    required this.builder,
  });

  final MediaItem media;
  final int index;
  final TileCallbacks callbacks;
  final Widget Function(BuildContext context, MediaItem media, bool selected) builder;

  @override
  Widget build(BuildContext context) {
    final selected = callbacks.selectedIds.contains(media.id);
    final selectionActive = callbacks.selectedIds.isNotEmpty;

    return GestureDetector(
      onTap: () {
        if (selectionActive) {
          callbacks.onToggleSelection?.call(media);
        } else {
          callbacks.onPlayAt?.call(index);
        }
      },
      onLongPress: callbacks.onLongPress == null
          ? null
          : () => callbacks.onLongPress!.call(media),
      child: builder(context, media, selected),
    );
  }
}

class _VideoListMode extends StatelessWidget {
  const _VideoListMode({
    required this.videos,
    required this.selectionActive,
    required this.selectedIds,
    this.onPlayAt,
    this.onToggleSelection,
    this.onLongPress,
    this.onOpenActions,
  });

  final List<MediaItem> videos;
  final bool selectionActive;
  final Set<String> selectedIds;
  final ValueChanged<int>? onPlayAt;
  final ValueChanged<MediaItem>? onToggleSelection;
  final ValueChanged<MediaItem>? onLongPress;
  final ValueChanged<MediaItem>? onOpenActions;

  @override
  Widget build(BuildContext context) {
    final callbacks = (
      selectedIds: selectedIds,
      onPlayAt: onPlayAt,
      onToggleSelection: onToggleSelection,
      onLongPress: onLongPress,
      onOpenActions: onOpenActions,
    );
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.sm),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        return _TileBase(
          media: video,
          index: index,
          callbacks: callbacks,
          builder: (context, media, selected) => _VideoListRow(
            video: media,
            selected: selected,
            selectionActive: selectionActive,
            onOpenActions: callbacks.onOpenActions,
          ),
        );
      },
    );
  }
}

class _VideoListRow extends StatelessWidget {
  const _VideoListRow({
    required this.video,
    required this.selected,
    required this.selectionActive,
    this.onOpenActions,
  });

  final MediaItem video;
  final bool selected;
  final bool selectionActive;
  final ValueChanged<MediaItem>? onOpenActions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: selected ? theme.colorScheme.primary.withValues(alpha: 0.12) : null,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: 6),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 120,
              height: 68,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  LibraryThumbnail(
                    path: video.thumbnailPath,
                    placeholderIcon: Icons.movie_creation_outlined,
                  ),
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: _DurationBadge(duration: video.duration.formatted),
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
                        valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                      ),
                    ),
                ],
              ),
            ),
          ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.displayTitle,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${video.format ?? 'video'} • ${FileSizeFormatter.format(video.fileSize)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    video.folderPath.split('/').last,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7), fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (selectionActive)
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              )
            else
              IconButton(
                icon: const Icon(Icons.more_vert_rounded, size: 18),
                color: theme.colorScheme.onSurfaceVariant,
                onPressed: onOpenActions == null ? null : () => onOpenActions!(video),
              ),
          ],
        )
      )
    ;
  }
}

class _VideoGridMode extends StatelessWidget {
  const _VideoGridMode({
    required this.videos,
    required this.selectionActive,
    required this.selectedIds,
    this.onPlayAt,
    this.onToggleSelection,
    this.onLongPress,
    this.onOpenActions,
  });

  final List<MediaItem> videos;
  final bool selectionActive;
  final Set<String> selectedIds;
  final ValueChanged<int>? onPlayAt;
  final ValueChanged<MediaItem>? onToggleSelection;
  final ValueChanged<MediaItem>? onLongPress;
  final ValueChanged<MediaItem>? onOpenActions;

  @override
  Widget build(BuildContext context) {
    final callbacks = (
      selectedIds: selectedIds,
      onPlayAt: onPlayAt,
      onToggleSelection: onToggleSelection,
      onLongPress: onLongPress,
      onOpenActions: onOpenActions,
    );
    return GridView.builder(
      padding: const EdgeInsets.all(AppDimensions.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.86,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        return _TileBase(
          media: video,
          index: index,
          callbacks: callbacks,
          builder: (context, media, selected) => _VideoGridCard(
            video: media,
            selected: selected,
            selectionActive: selectionActive,
          ),
        );
      },
    );
  }
}

class _VideoGridCard extends StatelessWidget {
  const _VideoGridCard({required this.video, required this.selected, required this.selectionActive});

  final MediaItem video;
  final bool selected;
  final bool selectionActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
          width: selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                LibraryThumbnail(path: video.thumbnailPath, placeholderIcon: Icons.movie_creation_outlined),
                if (selectionActive)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Icon(
                      selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                      color: selected ? theme.colorScheme.primary : Colors.white,
                    ),
                  ),
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: _DurationBadge(duration: video.duration.formatted),
                ),
                if (video.hasResumePosition)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: LinearProgressIndicator(
                      value: video.progressPercent,
                      minHeight: 3,
                      backgroundColor: Colors.black26,
                      valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              video.displayTitle,
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoLargeMode extends StatelessWidget {
  const _VideoLargeMode({
    required this.videos,
    required this.selectionActive,
    required this.selectedIds,
    this.onPlayAt,
    this.onToggleSelection,
    this.onLongPress,
    this.onOpenActions,
  });

  final List<MediaItem> videos;
  final bool selectionActive;
  final Set<String> selectedIds;
  final ValueChanged<int>? onPlayAt;
  final ValueChanged<MediaItem>? onToggleSelection;
  final ValueChanged<MediaItem>? onLongPress;
  final ValueChanged<MediaItem>? onOpenActions;

  @override
  Widget build(BuildContext context) {
    final callbacks = (
      selectedIds: selectedIds,
      onPlayAt: onPlayAt,
      onToggleSelection: onToggleSelection,
      onLongPress: onLongPress,
      onOpenActions: onOpenActions,
    );
    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.md),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _TileBase(
            media: video,
            index: index,
            callbacks: callbacks,
            builder: (context, media, selected) => _VideoLargeCard(
              video: media,
              selected: selected,
              selectionActive: selectionActive,
              onOpenActions: callbacks.onOpenActions,
            ),
          ),
        );
      },
    );
  }
}

class _VideoLargeCard extends StatelessWidget {
  const _VideoLargeCard({
    required this.video,
    required this.selected,
    required this.selectionActive,
    this.onOpenActions,
  });

  final MediaItem video;
  final bool selected;
  final bool selectionActive;
  final ValueChanged<MediaItem>? onOpenActions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
          width: selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                LibraryThumbnail(path: video.thumbnailPath, placeholderIcon: Icons.movie_creation_outlined),
                if (selectionActive)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Icon(
                      selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                      color: selected ? theme.colorScheme.primary : Colors.white,
                      size: 22,
                    ),
                  ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: _DurationBadge(duration: video.duration.formatted),
                ),
                if (video.hasResumePosition)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: LinearProgressIndicator(
                      value: video.progressPercent,
                      minHeight: 3,
                      backgroundColor: Colors.black26,
                      valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.displayTitle,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${video.format ?? 'video'} • ${FileSizeFormatter.format(video.fileSize)} • ${video.folderPath.split('/').last}',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert_rounded),
                  color: theme.colorScheme.onSurfaceVariant,
                  onPressed:
                      onOpenActions == null ? null : () => onOpenActions!(video),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoComfortableGridMode extends StatelessWidget {
  const _VideoComfortableGridMode({
    required this.videos,
    required this.selectionActive,
    required this.selectedIds,
    this.onPlayAt,
    this.onToggleSelection,
    this.onLongPress,
    this.onOpenActions,
  });

  final List<MediaItem> videos;
  final bool selectionActive;
  final Set<String> selectedIds;
  final ValueChanged<int>? onPlayAt;
  final ValueChanged<MediaItem>? onToggleSelection;
  final ValueChanged<MediaItem>? onLongPress;
  final ValueChanged<MediaItem>? onOpenActions;

  @override
  Widget build(BuildContext context) {
    final callbacks = (
      selectedIds: selectedIds,
      onPlayAt: onPlayAt,
      onToggleSelection: onToggleSelection,
      onLongPress: onLongPress,
      onOpenActions: onOpenActions,
    );
    return GridView.builder(
      padding: const EdgeInsets.all(AppDimensions.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        return _TileBase(
          media: video,
          index: index,
          callbacks: callbacks,
          builder: (context, media, selected) => _VideoComfortableCard(
            video: media,
            selected: selected,
            selectionActive: selectionActive,
          ),
        );
      },
    );
  }
}

class _VideoComfortableCard extends StatelessWidget {
  const _VideoComfortableCard({required this.video, required this.selected, required this.selectionActive});

  final MediaItem video;
  final bool selected;
  final bool selectionActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
          width: selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 2,
            child: Stack(
              fit: StackFit.expand,
              children: [
                LibraryThumbnail(path: video.thumbnailPath, placeholderIcon: Icons.movie_creation_outlined),
                if (selectionActive)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Icon(
                      selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                      color: selected ? theme.colorScheme.primary : Colors.white,
                    ),
                  ),
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: _DurationBadge(duration: video.duration.formatted),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    video.displayTitle,
                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoCompactMode extends StatelessWidget {
  const _VideoCompactMode({
    required this.videos,
    required this.selectionActive,
    required this.selectedIds,
    this.onPlayAt,
    this.onToggleSelection,
    this.onLongPress,
    this.onOpenActions,
  });

  final List<MediaItem> videos;
  final bool selectionActive;
  final Set<String> selectedIds;
  final ValueChanged<int>? onPlayAt;
  final ValueChanged<MediaItem>? onToggleSelection;
  final ValueChanged<MediaItem>? onLongPress;
  final ValueChanged<MediaItem>? onOpenActions;

  @override
  Widget build(BuildContext context) {
    final callbacks = (
      selectedIds: selectedIds,
      onPlayAt: onPlayAt,
      onToggleSelection: onToggleSelection,
      onLongPress: onLongPress,
      onOpenActions: onOpenActions,
    );
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        return _TileBase(
          media: video,
          index: index,
          callbacks: callbacks,
          builder: (context, media, selected) => _VideoCompactRow(
            video: media,
            selected: selected,
            selectionActive: selectionActive,
            onOpenActions: callbacks.onOpenActions,
          ),
        );
      },
    );
  }
}

class _VideoCompactRow extends StatelessWidget {
  const _VideoCompactRow({
    required this.video,
    required this.selected,
    required this.selectionActive,
    this.onOpenActions,
  });

  final MediaItem video;
  final bool selected;
  final bool selectionActive;
  final ValueChanged<MediaItem>? onOpenActions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: selected ? theme.colorScheme.primary.withValues(alpha: 0.12) : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Row(
        children: [
          if (selectionActive)
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              size: 18,
            )
          else
            Icon(
              Icons.movie_creation_outlined,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              video.displayTitle,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            video.duration.formatted,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
          if (!selectionActive)
            GestureDetector(
              onTap: onOpenActions == null ? null : () => onOpenActions!(video),
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.more_vert_rounded,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DurationBadge extends StatelessWidget {
  const _DurationBadge({required this.duration});

  final String duration;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        duration,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500),
      ),
    );
  }
}
