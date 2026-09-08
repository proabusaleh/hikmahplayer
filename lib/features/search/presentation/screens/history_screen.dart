import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/repositories/history_repository.dart';
import '../../../../core/storage/repositories/media_repository.dart';
import '../../../../presentation/providers/history_provider.dart';
import '../../../../presentation/providers/library_provider.dart';
import '../../../../presentation/providers/media_provider.dart';
import '../../../../presentation/providers/player_provider.dart';
import '../../../../presentation/screens/library/shared/library_thumbnail.dart';
import '../../../../shared/utils/format.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final historyAsync = ref.watch(playHistoryProvider);
    final mediaAsync = ref.watch(mediaItemsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          if (historyAsync.valueOrNull?.isNotEmpty ?? false)
            IconButton(
              tooltip: 'Clear history',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear History'),
                    content:
                        const Text('Remove all play history? This cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await ref.read(playHistoryProvider.notifier).clear();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('History cleared')),
                    );
                  }
                }
              },
            ),
        ],
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded,
                      size: 56,
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.3)),
                  const SizedBox(height: 12),
                  Text('Nothing played yet',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Your play history will appear here.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          final mediaMap = mediaAsync.whenOrNull(
            data: (items) => {for (final m in items) m.id: m},
          );

          final grouped = <String, List<PlayHistoryData>>{};
          for (final entry in entries) {
            final date =
                DateTime.fromMillisecondsSinceEpoch(entry.playedAt);
            final key =
                '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            (grouped[key] ??= []).add(entry);
          }

          return ListView(
            children: [
              for (final MapEntry(key: dateKey, value: dayEntries)
                  in grouped.entries) ...[
                _DayHeader(
                    dateKey: dateKey,
                    entryCount: dayEntries.length,
                    totalMs: dayEntries.fold<int>(
                        0, (sum, e) => sum + e.durationPlayed)),
                for (final entry in dayEntries) ...[
                  _HistoryTile(
                    entry: entry,
                    item: mediaMap?[entry.mediaId],
                    onTap: () {
                      final item = mediaMap?[entry.mediaId];
                      if (item != null) {
                        ref
                            .read(playerControllerProvider.notifier)
                            .playQueue([item]);
                      }
                    },
                  ),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({
    required this.dateKey,
    required this.entryCount,
    required this.totalMs,
  });

  final String dateKey;
  final int entryCount;
  final int totalMs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = DateTime.parse(dateKey);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDay = DateTime(date.year, date.month, date.day);
    final diff = today.difference(entryDay).inDays;

    final String label;
    if (diff == 0) {
      label = 'TODAY';
    } else if (diff == 1) {
      label = 'YESTERDAY';
    } else if (diff < 7) {
      label = '${diff.toString().toUpperCase()} DAYS AGO';
    } else {
      label = Fmt.date(date).toUpperCase();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.8,
            ),
          ),
          const Spacer(),
          Text(
            '$entryCount plays \u00b7 ${Fmt.duration(Duration(milliseconds: totalMs))}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.entry,
    required this.item,
    required this.onTap,
  });

  final PlayHistoryData entry;
  final MediaItem? item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = item?.displayTitle ?? entry.mediaId;
    final subtitle = Fmt.duration(
        Duration(milliseconds: entry.durationPlayed));

    return ListTile(
      leading: item != null
          ? LibraryThumbnail(
              path: item!.thumbnailPath ?? item!.albumArtPath,
              placeholderIcon: item!.isVideo
                  ? Icons.movie_rounded
                  : Icons.music_note_rounded,
            )
          : Icon(Icons.music_note_rounded,
              color: theme.colorScheme.onSurfaceVariant),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall,
      ),
      trailing: entry.completed
          ? Icon(Icons.check_circle_rounded,
              size: 18, color: theme.colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}
