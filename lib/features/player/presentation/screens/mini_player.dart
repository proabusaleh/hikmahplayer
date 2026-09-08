import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../presentation/providers/player_provider.dart';
import '../../domain/models/media_item.dart';
import 'player_screen.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerControllerProvider);
    final item = state.currentItem;
    if (item == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final notifier = ref.read(playerControllerProvider.notifier);
    final subtitle =
        item.type == MediaType.audio
            ? ([item.artist, item.album].whereType<String>().join(' — ').isEmpty
                ? 'Now Playing'
                : [item.artist, item.album].whereType<String>().join(' — '))
            : item.uri;

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (details.primaryDelta != null && details.primaryDelta! < -8) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PlayerScreen()),
          );
        }
      },
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
              width: 0.5,
            ),
          ),
        ),
        child: Column(
          children: [
            LinearProgressIndicator(
              value:
                  state.duration > Duration.zero
                      ? state.position.inMilliseconds /
                          state.duration.inMilliseconds
                      : null,
              minHeight: 2,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
            ),
            Expanded(
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PlayerScreen()),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child:
                              item.artworkUri == null
                                  ? ColoredBox(
                                    color: theme.colorScheme.primaryContainer,
                                    child: Icon(
                                      item.type == MediaType.audio
                                          ? Icons.music_note_rounded
                                          : Icons.movie_rounded,
                                      size: 20,
                                      color:
                                          theme.colorScheme.onPrimaryContainer,
                                    ),
                                  )
                                  : Image.network(
                                    item.artworkUri!,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (_, _, _) => ColoredBox(
                                          color:
                                              theme
                                                  .colorScheme
                                                  .primaryContainer,
                                          child: Icon(
                                            item.type == MediaType.audio
                                                ? Icons.music_note_rounded
                                                : Icons.movie_rounded,
                                            size: 20,
                                          ),
                                        ),
                                  ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Queue',
                        icon: Icon(
                          Icons.queue_music_rounded,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () {},
                      ),
                      IconButton(
                        tooltip: state.isPlaying ? 'Pause' : 'Play',
                        icon: Icon(
                          state.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 22,
                        ),
                        onPressed: () => notifier.playPause(),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        icon: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () => notifier.clearQueue(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
