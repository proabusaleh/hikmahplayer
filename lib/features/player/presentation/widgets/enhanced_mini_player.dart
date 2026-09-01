import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/media_item.dart';
import '../providers/player_state_provider.dart';
import '../screens/audio_player_screen.dart';
import '../screens/enhanced_video_player_screen.dart';

class EnhancedMiniPlayer extends ConsumerWidget {
  const EnhancedMiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerStateProvider);
    final controller = ref.read(playerStateProvider.notifier);
    final theme = Theme.of(context);

    if (!state.hasMedia) return const SizedBox.shrink();

    final media = state.currentMedia!;

    return Material(
      elevation: 8,
      color: theme.colorScheme.surfaceContainerHigh,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => media.type == MediaType.video
                  ? EnhancedVideoPlayerScreen(mediaId: media.id)
                  : const AudioPlayerScreen(),
            ),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ─── Progress Bar (thin) ───
            LinearProgressIndicator(
              value: state.progress,
              minHeight: 2,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
            ),

            // ─── Content ───
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  // ─── Thumbnail ───
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      media.type == MediaType.video ? Icons.movie : Icons.music_note,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // ─── Title & Artist ───
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          media.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          media.artist ??
                              media.album ??
                              'Unknown',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // ─── Controls ───
                  IconButton(
                    icon: const Icon(Icons.skip_previous),
                    iconSize: 24,
                    onPressed:
                        state.hasPrevious ? controller.previous : null,
                  ),
                  IconButton(
                    icon: Icon(
                      state.isPlaying ? Icons.pause : Icons.play_arrow,
                    ),
                    iconSize: 32,
                    onPressed: controller.togglePlayPause,
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    iconSize: 24,
                    onPressed: state.hasNext ? controller.next : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
