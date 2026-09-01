import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/duration_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/playback_state.dart';
import '../providers/player_state_provider.dart';

class EnhancedPlayerControls extends ConsumerWidget {
  final VoidCallback onInteraction;

  const EnhancedPlayerControls({super.key, required this.onInteraction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerStateProvider);
    final controller = ref.read(playerStateProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.7),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withValues(alpha: 0.8),
          ],
          stops: const [0.0, 0.2, 0.7, 1.0],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // ─── TOP BAR ───
            _buildTopBar(context, state),

            const Spacer(),

            // ─── CENTER CONTROLS ───
            _buildCenterControls(context, state, controller),

            const Spacer(),

            // ─── BOTTOM CONTROLS ───
            _buildBottomControls(context, state, controller),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, PlaybackState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back,
                color: AppColors.playerControls, size: 28),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.currentMedia?.title ?? '',
                  style: const TextStyle(
                    color: AppColors.playerControls,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (state.currentMedia?.artist != null)
                  Text(
                    state.currentMedia!.artist!,
                    style: TextStyle(
                      color: AppColors.playerControls.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.picture_in_picture_alt_outlined,
                color: AppColors.playerControls),
            onPressed: () {
              onInteraction();
              // TODO: Enter PiP mode
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert,
                color: AppColors.playerControls),
            onPressed: () {
              onInteraction();
              _showMoreOptions(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCenterControls(
    BuildContext context,
    PlaybackState state,
    PlayerStateNotifier controller,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _CircleButton(
          icon: Icons.skip_previous,
          size: 40,
          onTap: () {
            onInteraction();
            controller.previous();
          },
          enabled: state.hasPrevious,
        ),
        _CircleButton(
          icon: Icons.replay_10,
          size: 40,
          onTap: () {
            onInteraction();
            controller.seekBackward();
          },
        ),
        _CircleButton(
          icon: state.isPlaying ? Icons.pause : Icons.play_arrow,
          size: 64,
          onTap: () {
            onInteraction();
            controller.togglePlayPause();
          },
          isPrimary: true,
          isLoading: state.isLoading || state.isBuffering,
        ),
        _CircleButton(
          icon: Icons.forward_10,
          size: 40,
          onTap: () {
            onInteraction();
            controller.seekForward();
          },
        ),
        _CircleButton(
          icon: Icons.skip_next,
          size: 40,
          onTap: () {
            onInteraction();
            controller.next();
          },
          enabled: state.hasNext,
        ),
      ],
    );
  }

  Widget _buildBottomControls(
    BuildContext context,
    PlaybackState state,
    PlayerStateNotifier controller,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // ─── Seek Bar with Times ───
          Row(
            children: [
              Text(
                state.position.formatted,
                style: const TextStyle(
                  color: AppColors.playerControls,
                  fontSize: 12,
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    activeTrackColor: AppColors.seekBarPlayed,
                    inactiveTrackColor: AppColors.seekBarRemaining,
                    thumbColor: AppColors.playerControls,
                    overlayColor: AppColors.seekBarPlayed.withValues(alpha: 0.2),
                  ),
                  child: Slider(
                    value: state.progress.clamp(0.0, 1.0),
                    onChanged: (value) {
                      onInteraction();
                      final pos = Duration(
                        milliseconds: (state.duration.inMilliseconds * value)
                            .round(),
                      );
                      controller.seekTo(pos);
                    },
                  ),
                ),
              ),
              Text(
                state.duration.formatted,
                style: const TextStyle(
                  color: AppColors.playerControls,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          // ─── Bottom Row: Speed, Loop, Shuffle, Fit ───
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _IconWithLabel(
                icon: Icons.speed,
                label: '${state.speed}x',
                onTap: () {
                  onInteraction();
                  _showSpeedSelector(context, controller, state.speed);
                },
              ),
              _IconWithLabel(
                icon: _loopIcon(state.loopMode),
                label: _loopLabel(state.loopMode),
                onTap: () {
                  onInteraction();
                  controller.cycleLoopMode();
                },
                active: state.loopMode != LoopMode.none,
              ),
              _IconWithLabel(
                icon: Icons.shuffle,
                label: 'Shuffle',
                onTap: () {
                  onInteraction();
                  controller.toggleShuffle();
                },
                active: state.shuffleEnabled,
              ),
              _IconWithLabel(
                icon: Icons.aspect_ratio,
                label: state.videoFit.label,
                onTap: () {
                  onInteraction();
                  _cycleVideoFit(controller, state.videoFit);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _loopIcon(LoopMode mode) => switch (mode) {
        LoopMode.none => Icons.repeat,
        LoopMode.all => Icons.repeat,
        LoopMode.one => Icons.repeat_one,
      };

  String _loopLabel(LoopMode mode) => switch (mode) {
        LoopMode.none => 'Off',
        LoopMode.all => 'All',
        LoopMode.one => 'One',
      };

  void _cycleVideoFit(PlayerStateNotifier controller, VideoFit current) {
    final next = switch (current) {
      VideoFit.contain => VideoFit.cover,
      VideoFit.cover => VideoFit.fill,
      VideoFit.fill => VideoFit.natural,
      VideoFit.natural => VideoFit.contain,
    };
    controller.setVideoFit(next);
  }

  void _showSpeedSelector(
    BuildContext context,
    PlayerStateNotifier controller,
    double currentSpeed,
  ) {
    const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Playback Speed',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ...speeds.map((speed) {
              final isSelected = speed == currentSpeed;
              return ListTile(
                title: Text(
                  '${speed}x',
                  style: TextStyle(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check,
                        color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () {
                  controller.setSpeed(speed);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.closed_caption_outlined,
                color: Colors.white),
            title: const Text('Subtitles',
                style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              // TODO: Show subtitle selector
            },
          ),
          ListTile(
            leading:
                const Icon(Icons.queue_music, color: Colors.white),
            title:
                const Text('Queue', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              // TODO: Show queue
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.white),
            title: const Text('Media Info',
                style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              // TODO: Show info
            },
          ),
        ],
      ),
    );
  }
}

// ─── Circular Icon Button ───
class _CircleButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;
  final bool isPrimary;
  final bool enabled;
  final bool isLoading;

  const _CircleButton({
    required this.icon,
    required this.size,
    required this.onTap,
    this.isPrimary = false,
    this.enabled = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonSize = isPrimary ? size + 24 : size + 16;

    return Material(
      color: isPrimary
          ? AppColors.playerControls.withValues(alpha: 0.2)
          : Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: buttonSize,
          height: buttonSize,
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: size * 0.6,
                    height: size * 0.6,
                    child: const CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.playerControls),
                    ),
                  )
                : Icon(
                    icon,
                    size: size,
                    color: enabled
                        ? AppColors.playerControls
                        : AppColors.playerControls.withValues(alpha: 0.4),
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── Icon with Label (bottom row) ───
class _IconWithLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  const _IconWithLabel({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = active
        ? Theme.of(context).colorScheme.primary
        : AppColors.playerControls;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
