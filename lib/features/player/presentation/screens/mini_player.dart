import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../shared/utils/format.dart';
import '../../domain/models/media_item.dart';
import 'player_screen.dart';

/// Compact now-playing bar pinned above the navigation bar.
///
/// Shows the current item with play/pause and a dismiss action; tapping opens
/// the full [PlayerScreen].
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final playback = AppScope.of(context).playback;
    return ValueListenableBuilder<String?>(
      valueListenable: playback.currentMediaId,
      builder: (context, _, _) {
        final item = playback.currentItem;
        if (item == null) return const SizedBox.shrink();
        return Material(
          color: Theme.of(context).colorScheme.surface,
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const PlayerScreen()),
              );
            },
            child: Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: item.artworkUri == null
                          ? ColoredBox(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
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
                              errorBuilder: (_, _, _) => const ColoredBox(
                                color: Colors.black26,
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
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          item.type == MediaType.audio
                              ? ([item.artist, item.album].whereType<String>().join(' — ').isEmpty
                                  ? 'Now playing'
                                  : [item.artist, item.album].whereType<String>().join(' — '))
                              : _positionLabel(playback),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: playback.isPlaying,
                    builder: (context, isPlaying, _) {
                      return IconButton(
                        tooltip: isPlaying ? 'Pause' : 'Play',
                        icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                        onPressed: () => playback.playPause(),
                      );
                    },
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close),
                    onPressed: () => playback.clearQueue(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _positionLabel(dynamic playback) {
    return '${Fmt.duration(playback.position.value)} / '
        '${Fmt.duration(playback.duration.value)}';
  }
}
