import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/duration_extensions.dart';
import '../../../../core/storage/repositories/media_repository.dart';
import '../../../providers/favorites_provider.dart' show favoriteIdsProvider;
import '../../../providers/library_provider.dart' show MediaItemDisplay;
import '../../../providers/player_provider.dart';
import '../../../providers/services_provider.dart';

/// Bottom sheet of per-song actions. Player, favorite and delete are wired to
/// real services; native-dependent actions (ID3 editing, ringtone, share,
/// album art) are presented as "soon" entries to keep the surface complete.
Future<void> showSongActionSheet(
  BuildContext context, {
  required MediaItem song,
  required List<MediaItem> queue,
  required int index,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => _SongActionSheet(
      song: song,
      queue: queue,
      index: index,
    ),
  );
}

class _SongActionSheet extends ConsumerWidget {
  const _SongActionSheet({
    required this.song,
    required this.queue,
    required this.index,
  });

  final MediaItem song;
  final List<MediaItem> queue;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isFavorite = ref.watch(favoriteIdsProvider).contains(song.id);

    void playNext() {
      Navigator.pop(context);
      ref.read(playerControllerProvider.notifier).playNext(song);
    }

    void addToQueue() {
      Navigator.pop(context);
      ref.read(playerControllerProvider.notifier).addToQueue(song);
    }

    void toggleFavorite() async {
      Navigator.pop(context);
      await ref.read(appServicesProvider).media.setFavorite(song.id, !isFavorite);
    }

    void delete() async {
      Navigator.pop(context);
      await ref.read(appServicesProvider).media.removeByIds([song.id]);
    }

    void showInfo() {
      Navigator.pop(context);
      _showSongInfoSheet(context, song);
    }

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 52,
                    height: 52,
                    color: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.music_note_rounded,
                      size: 22,
                      color: theme.colorScheme.onPrimaryContainer,
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
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${song.artist ?? 'Unknown Artist'} • ${song.duration.formatted}',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _SongActionTile(
            icon: Icons.skip_next_rounded,
            label: 'Play Next',
            onTap: playNext,
          ),
          _SongActionTile(
            icon: Icons.queue_rounded,
            label: 'Add to Queue',
            onTap: addToQueue,
          ),
          _SongActionTile(
            icon: isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            label: isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
            onTap: toggleFavorite,
          ),
          _SongActionTile(
            icon: Icons.edit_note_rounded,
            label: 'Edit ID3 Tags',
            comingSoon: true,
          ),
          _SongActionTile(
            icon: Icons.notifications_active_outlined,
            label: 'Set as Ringtone',
            comingSoon: true,
          ),
          _SongActionTile(
            icon: Icons.album_outlined,
            label: 'Set Album Art',
            comingSoon: true,
          ),
          _SongActionTile(
            icon: Icons.info_outline_rounded,
            label: 'Details',
            onTap: showInfo,
          ),
          const Divider(height: 1),
          _SongActionTile(
            icon: Icons.delete_outline_rounded,
            label: 'Delete',
            destructive: true,
            onTap: delete,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SongActionTile extends StatelessWidget {
  const _SongActionTile({
    required this.icon,
    required this.label,
    this.onTap,
    this.comingSoon = false,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool comingSoon;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = destructive
        ? theme.colorScheme.error
        : comingSoon
        ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
        : theme.colorScheme.onSurface;

    return ListTile(
      dense: true,
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(color: color, fontWeight: FontWeight.w500),
      ),
      enabled: !comingSoon,
      trailing: comingSoon
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Soon',
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            )
          : null,
      onTap: onTap,
    );
  }
}

void _showSongInfoSheet(BuildContext context, MediaItem song) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final theme = Theme.of(context);
      final rows = <(String, String)>[
        ('Title', song.displayTitle),
        ('Artist', song.artist ?? '—'),
        ('Album', song.album ?? '—'),
        ('Genre', song.genre ?? '—'),
        ('Track', song.trackNumber != null ? '${song.trackNumber}' : '—'),
        ('Format', song.format ?? '—'),
        ('Duration', song.duration.formatted),
        ('Size', '${(song.fileSize / 1024 / 1024).toStringAsFixed(1)} MB'),
        ('Bitrate', song.bitRate != null ? '${song.bitRate} bps' : '—'),
        ('Sample rate', song.sampleRate != null ? '${song.sampleRate} Hz' : '—'),
        ('Folder', song.folderPath),
        ('Plays', '${song.playCount}'),
        ('Favorite', song.isFavorite ? 'Yes' : 'No'),
      ];
      return SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Text(
                'Details',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 4),
            for (final (label, value) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        label,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        value,
                        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      );
    },
  );
}