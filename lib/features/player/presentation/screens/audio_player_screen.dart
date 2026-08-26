import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/duration_extensions.dart';
import '../../domain/models/playback_state.dart';
import '../providers/player_state_provider.dart';

class AudioPlayerScreen extends ConsumerWidget {
  const AudioPlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerStateProvider);
    final controller = ref.read(playerStateProvider.notifier);
    final theme = Theme.of(context);

    if (!state.hasMedia) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('No media playing')),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.3),
              theme.colorScheme.surface,
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ─── Top Bar ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down, size: 32),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    Column(
                      children: [
                        Text('PLAYING FROM',
                            style: theme.textTheme.labelSmall),
                        Text(
                          state.currentMedia?.album ?? 'Library',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // ─── Album Art ───
              Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: theme.colorScheme.primaryContainer,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: state.currentMedia?.artworkUri != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.network(
                          state.currentMedia!.artworkUri!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _defaultArt(theme),
                        ),
                      )
                    : _defaultArt(theme),
              ),

              const Spacer(),

              // ─── Song Info ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    Text(
                      state.currentMedia?.title ?? '',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.currentMedia?.artist ?? 'Unknown Artist',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ─── Seek Bar ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 8),
                      ),
                      child: Slider(
                        value: state.progress.clamp(0.0, 1.0),
                        onChanged: (value) {
                          final pos = Duration(
                            milliseconds:
                                (state.duration.inMilliseconds * value)
                                    .round(),
                          );
                          controller.seekTo(pos);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(state.position.formatted,
                              style: theme.textTheme.bodySmall),
                          Text(state.duration.formatted,
                              style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ─── Playback Controls ───
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.shuffle,
                        color: state.shuffleEnabled
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      onPressed: controller.toggleShuffle,
                    ),
                    IconButton(
                      iconSize: 40,
                      icon: const Icon(Icons.skip_previous),
                      onPressed:
                          state.hasPrevious ? controller.previous : null,
                    ),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        iconSize: 36,
                        color: theme.colorScheme.onPrimary,
                        icon: Icon(
                          state.isPlaying ? Icons.pause : Icons.play_arrow,
                        ),
                        onPressed: controller.togglePlayPause,
                      ),
                    ),
                    IconButton(
                      iconSize: 40,
                      icon: const Icon(Icons.skip_next),
                      onPressed: state.hasNext ? controller.next : null,
                    ),
                    IconButton(
                      icon: Icon(
                        state.loopMode == LoopMode.one
                            ? Icons.repeat_one
                            : Icons.repeat,
                        color: state.loopMode != LoopMode.none
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      onPressed: controller.cycleLoopMode,
                    ),
                  ],
                ),
              ),

              // ─── Bottom Actions ───
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.favorite_border),
                      onPressed: () {
                        // TODO: Toggle favorite
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_outlined),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.queue_music_outlined),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _defaultArt(ThemeData theme) {
    return Center(
      child: Icon(
        Icons.music_note,
        size: 120,
        color: theme.colorScheme.onPrimaryContainer,
      ),
    );
  }
}
