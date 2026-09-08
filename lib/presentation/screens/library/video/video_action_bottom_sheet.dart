import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/extensions/duration_extensions.dart';
import '../../../../core/storage/repositories/media_repository.dart';
import '../../../providers/favorites_provider.dart' show favoriteIdsProvider;
import '../../../providers/library_provider.dart' show MediaItemDisplay;
import '../../../providers/player_provider.dart';
import '../../../providers/services_provider.dart';

/// Bottom sheet of per-video actions. Real API actions (play, queue, favorite,
/// delete, share) are wired; native-only actions (rename file, hide, ID3 tags)
/// are surfaced as disabled "coming soon" entries so the sheet is complete.
Future<void> showVideoActionSheet(
  BuildContext context, {
  required MediaItem video,
  required List<MediaItem> queue,
  required int index,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => _VideoActionSheet(
      video: video,
      queue: queue,
      index: index,
    ),
  );
}

class _VideoActionSheet extends ConsumerWidget {
  const _VideoActionSheet({
    required this.video,
    required this.queue,
    required this.index,
  });

  final MediaItem video;
  final List<MediaItem> queue;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isFavorite = ref.watch(favoriteIdsProvider).contains(video.id);

    void playNow() {
      Navigator.pop(context);
      ref.read(playerControllerProvider.notifier).playQueue(queue, startIndex: index);
    }

    void playNext() {
      Navigator.pop(context);
      ref.read(playerControllerProvider.notifier).playNext(video);
    }

    void addToQueue() {
      Navigator.pop(context);
      ref.read(playerControllerProvider.notifier).addToQueue(video);
    }

    void toggleFavorite() async {
      Navigator.pop(context);
      await ref
          .read(appServicesProvider)
          .media
          .setFavorite(video.id, !isFavorite);
    }

    void shareVideo() {
      Navigator.pop(context);
      SharePlus.instance.share(ShareParams(
        text: video.displayTitle,
        files: [XFile(video.filePath)],
      ));
    }

    void copyPath() {
      Navigator.pop(context);
      Clipboard.setData(ClipboardData(text: video.filePath));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Path copied to clipboard')),
      );
    }

    void moveVideo() async {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Move: use file manager to relocate')),
      );
    }

    void delete() async {
      Navigator.pop(context);
      await ref.read(appServicesProvider).media.removeByIds([video.id]);
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
                    height: 36,
                    color: theme.colorScheme.surfaceContainerHighest,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.movie_creation_outlined,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
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
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (video.format != null)
                        Text(
                          '${video.format} • ${video.duration.formatted}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _ActionListTile(
            icon: Icons.play_arrow_rounded,
            label: 'Play Now',
            onTap: playNow,
          ),
          _ActionListTile(
            icon: Icons.skip_next_rounded,
            label: 'Play Next',
            onTap: playNext,
          ),
          _ActionListTile(
            icon: Icons.queue_rounded,
            label: 'Add to Queue',
            onTap: addToQueue,
          ),
          _ActionListTile(
            icon: isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            label: isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
            onTap: toggleFavorite,
          ),
          _ActionListTile(
            icon: Icons.share_rounded,
            label: 'Share',
            onTap: shareVideo,
          ),
          _ActionListTile(
            icon: Icons.content_copy_rounded,
            label: 'Copy Path',
            onTap: copyPath,
          ),
          _ActionListTile(
            icon: Icons.drive_file_move_rounded,
            label: 'Move',
            onTap: moveVideo,
          ),
          _ActionListTile(
            icon: Icons.drive_file_rename_outline_rounded,
            label: 'Rename',
            comingSoon: true,
          ),
          _ActionListTile(
            icon: Icons.visibility_off_outlined,
            label: 'Hide',
            comingSoon: true,
          ),
          _ActionListTile(
            icon: Icons.local_offer_outlined,
            label: 'Edit Tags',
            comingSoon: true,
          ),
          _ActionListTile(
            icon: Icons.info_outline_rounded,
            label: 'Details',
            onTap: () {
              Navigator.pop(context);
              _showVideoInfoSheet(context, video);
            },
          ),
          const Divider(height: 1),
          _ActionListTile(
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

class _ActionListTile extends StatelessWidget {
  const _ActionListTile({
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
        style: theme.textTheme.bodyMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
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
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          : null,
      onTap: onTap,
    );
  }
}

void _showVideoInfoSheet(BuildContext context, MediaItem video) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final theme = Theme.of(context);
      final rows = <(String, String)>[
        ('Name', video.displayTitle),
        ('Folder', video.folderPath),
        ('Format', video.format ?? '—'),
        ('Duration', video.duration.formatted),
        ('Size', '${(video.fileSize / 1024 / 1024).toStringAsFixed(1)} MB'),
        ('Resolution', video.resolution ?? '—'),
        if (video.width != null && video.height != null)
          ('Dimensions', '${video.width} × ${video.height}'),
        ('Bitrate', video.bitRate != null ? '${video.bitRate} bps' : '—'),
        ('Sample rate', video.sampleRate != null ? '${video.sampleRate} Hz' : '—'),
        ('Added', _date(video.dateAdded)),
        ('Modified', _date(video.dateModified)),
        ('Last played', video.lastPlayedAt?.toString().split('.').first ?? 'Never'),
        ('Plays', '${video.playCount}'),
        ('Favorite', video.isFavorite ? 'Yes' : 'No'),
      ];
      return SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Text('Details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 4),
            for (final (label, value) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 110,
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

String _date(int? epochMs) {
  if (epochMs == null || epochMs == 0) return '—';
  return DateTime.fromMillisecondsSinceEpoch(epochMs).toString().split('.').first;
}