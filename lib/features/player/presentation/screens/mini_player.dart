import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../presentation/providers/player_provider.dart';
import '../../../../shared/utils/format.dart';
import '../../domain/models/media_item.dart';
import 'player_screen.dart';

/// Compact now-playing bar pinned above the bottom navigation.
///
/// Surfaces the live [playerControllerProvider] state and offers a Play/Pause
/// toggle plus a dismiss action; tapping opens the full [PlayerScreen].
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerControllerProvider);
    final item = state.currentItem;
    if (item == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final notifier = ref.read(playerControllerProvider.notifier);
    final subtitle = item.type == MediaType.audio
        ? ([item.artist, item.album]
            .whereType<String>()
            .join(' — ')
            .isEmpty
            ? 'Now playing'
            : [item.artist, item.album].whereType<String>().join(' — '))
        : '${Fmt.duration(state.position)} / ${Fmt.duration(state.duration)}';

    return Material(
      color: theme.colorScheme.surface,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const PlayerScreen()),
          );
        },
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: item.artworkUri == null
                      ? ColoredBox(
                          color: theme.colorScheme.primaryContainer,
                          child: Icon(
                            item.type == MediaType.audio
                                ? Icons.music_note
                                : Icons.movie,
                            size: 22,
                          ),
                        )
                      : Image.network(
                          item.artworkUri!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => ColoredBox(
                            color: theme.colorScheme.primaryContainer,
                            child: Icon(
                              item.type == MediaType.audio
                                  ? Icons.music_note
                                  : Icons.movie,
                              size: 22,
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
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: state.isPlaying ? 'Pause' : 'Play',
                icon: Icon(state.isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: () => notifier.playPause(),
              ),
              IconButton(
                tooltip: 'Close',
                icon: const Icon(Icons.close),
                onPressed: () => notifier.clearQueue(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}