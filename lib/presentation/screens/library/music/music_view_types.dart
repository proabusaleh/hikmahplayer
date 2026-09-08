import 'package:flutter/material.dart';

import '../../../../core/extensions/duration_extensions.dart';
import '../../../../core/storage/repositories/media_repository.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../providers/library_provider.dart' show MediaItemDisplay;
import '../shared/library_thumbnail.dart';
import '../shared/library_view_mode.dart';
import 'music_library_provider.dart';

/// Reusable tiles for the music library. Each tile is a plain [StatelessWidget]
/// driven by callbacks so the renderers stay presentational.
class SongListViewTile extends StatelessWidget {
  const SongListViewTile({
    super.key,
    required this.song,
    required this.selected,
    required this.selectionActive,
    this.onTap,
    this.onLongPress,
    this.onOpenActions,
    this.trailing,
  });

  final MediaItem song;
  final bool selected;
  final bool selectionActive;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onOpenActions;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        color: selected ? theme.colorScheme.primary.withValues(alpha: 0.12) : null,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: 6),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    LibraryThumbnail(
                      path: song.albumArtPath,
                      placeholderIcon: Icons.music_note_rounded,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundColor: theme.colorScheme.onPrimaryContainer,
                    ),
                    if (selectionActive)
                      Container(
                        color: Colors.black.withValues(alpha: 0.45),
                        alignment: Alignment.center,
                        child: Icon(
                          selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                          color: selected ? theme.colorScheme.primary : Colors.white,
                          size: 22,
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
                    song.displayTitle,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    song.artist ?? 'Unknown Artist',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (song.isFavorite)
              Icon(Icons.favorite_rounded, size: 14, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              song.duration.formatted,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
            ),
            if (onOpenActions != null && !selectionActive)
              IconButton(
                icon: Icon(Icons.more_vert_rounded, size: 16, color: theme.colorScheme.onSurfaceVariant),
                onPressed: onOpenActions,
              ),
            if (selectionActive && trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

/// Dense row without artwork — used in compact view.
class SongCompactViewTile extends StatelessWidget {
  const SongCompactViewTile({
    super.key,
    required this.song,
    required this.selected,
    required this.selectionActive,
    this.onTap,
    this.onLongPress,
    this.onOpenActions,
  });

  final MediaItem song;
  final bool selected;
  final bool selectionActive;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onOpenActions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        color: selected ? theme.colorScheme.primary.withValues(alpha: 0.12) : null,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              child: Text(
                selectionActive ? '' : '${song.trackNumber ?? ''}',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              selectionActive
                  ? (selected ? Icons.check_circle_rounded : Icons.circle_outlined)
                  : Icons.music_note_rounded,
              size: 18,
              color: selectionActive
                  ? (selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant)
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                song.displayTitle,
                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13.5),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (song.isFavorite)
              Icon(Icons.favorite_rounded, size: 12, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              song.duration.formatted,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
            ),
            if (onOpenActions != null && !selectionActive)
              IconButton(
                icon: Icon(Icons.more_vert_rounded, size: 15, color: theme.colorScheme.onSurfaceVariant),
                onPressed: onOpenActions,
              ),
          ],
        ),
      ),
    );
  }
}

/// Album card shown in albums grids.
class AlbumGridCardTile extends StatelessWidget {
  const AlbumGridCardTile({
    super.key,
    required this.group,
    this.onTap,
  });

  final MusicGroup group;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cover = group.songs.firstWhere(
      (s) => (s.albumArtPath ?? '').isNotEmpty,
      orElse: () => group.songs.first,
    );

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  LibraryThumbnail(
                    path: cover.albumArtPath,
                    placeholderIcon: Icons.album_rounded,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                  ),
                  if (group.songCount > 1)
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${group.songCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            group.name,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            group.songs.first.artist ?? 'Unknown Artist',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Artist row shown in artists / genres lists.
class ArtistListViewTile extends StatelessWidget {
  const ArtistListViewTile({
    super.key,
    required this.group,
    this.onTap,
  });

  final MusicGroup group;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = group.name;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Text(
          name.isEmpty ? '?' : name[0].toUpperCase(),
          style: TextStyle(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(name, style: theme.textTheme.titleSmall),
      subtitle: Text(
        '${group.songCount} song${group.songCount == 1 ? '' : 's'}',
        style: theme.textTheme.bodySmall,
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 18,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// The icon used for a library view mode in its switcher.
IconData libraryViewIcon(LibraryViewMode mode) => switch (mode) {
      LibraryViewMode.list => Icons.view_agenda_rounded,
      LibraryViewMode.compact => Icons.view_headline_rounded,
      LibraryViewMode.grid => Icons.grid_view_rounded,
      LibraryViewMode.large => Icons.view_day_rounded,
      LibraryViewMode.gridComfortable => Icons.dashboard_rounded,
    };