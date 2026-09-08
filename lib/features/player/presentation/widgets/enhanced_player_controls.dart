import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/duration_extensions.dart';
import '../../../../core/di/app_scope.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/media_info_service.dart';
import '../../../../core/services/playback_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/format.dart';
import '../../../audio/domain/models/equalizer.dart';
import '../../domain/models/media_item.dart';
import '../../domain/models/media_track.dart';
import '../../domain/models/playback_settings.dart';
import '../../domain/models/playback_state.dart';
import '../providers/player_state_provider.dart';

class EnhancedPlayerControls extends ConsumerWidget {
  final VoidCallback onInteraction;
  final bool locked;
  final VoidCallback onLock;
  final VideoOrientation orientation;
  final ValueChanged<VideoOrientation> onSetOrientation;
  final VoidCallback onResetZoom;
  final void Function(Duration) onSeekEnd;
  final bool autoNext;
  final ValueChanged<bool> onAutoNextChanged;

  const EnhancedPlayerControls({
    super.key,
    required this.onInteraction,
    required this.locked,
    required this.onLock,
    required this.orientation,
    required this.onSetOrientation,
    required this.onResetZoom,
    required this.onSeekEnd,
    required this.autoNext,
    required this.onAutoNextChanged,
  });

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
            _buildTopBar(context, state, controller),

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

  Widget _buildTopBar(
    BuildContext context,
    PlaybackState state,
    PlayerStateNotifier controller,
  ) {
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
            icon: Icon(
              locked ? Icons.lock : Icons.lock_open_outlined,
              color: AppColors.playerControls,
            ),
            onPressed: () {
              onInteraction();
              onLock();
            },
          ),
          IconButton(
            icon: const Icon(Icons.aspect_ratio,
                color: AppColors.playerControls),
            onPressed: () {
              onInteraction();
              _showFitSelector(context, state.videoFit, controller);
            },
            tooltip: 'Aspect ratio',
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
    final seekStep = Duration(
      seconds: AppScope.of(context).prefs.seekStepSeconds,
    );
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
            controller.seekBackward(seekStep);
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
            controller.seekForward(seekStep);
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
          // ─── Quick seek chips ───
          _buildSeekChips(context, controller),
          const SizedBox(height: 8),

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
                    onChangeEnd: (value) {
                      final pos = Duration(
                        milliseconds: (state.duration.inMilliseconds * value)
                            .round(),
                      );
                      onSeekEnd(pos);
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
                  _showSpeedSelector(
                    context,
                    controller,
                    state.speed,
                    state.currentMedia?.id,
                  );
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
                  _showFitSelector(context, state.videoFit, controller);
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

  // ─── Quick seek chips (relative to configured step) ───

  Widget _buildSeekChips(
    BuildContext context,
    PlayerStateNotifier controller,
  ) {
    final step = AppScope.of(context).prefs.seekStepSeconds;
    const multipliers = [-6, -3, -1, 1, 3, 6];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final m in multipliers)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _SeekChip(
              label: m < 0
                  ? '-${(-m * step)}s'
                  : '+${(m * step)}s',
              onTap: () {
                onInteraction();
                final amount = Duration(seconds: (m * step).abs());
                if (m < 0) {
                  controller.seekBackward(amount);
                } else {
                  controller.seekForward(amount);
                }
              },
            ),
          ),
      ],
    );
  }

  // ─── Speed selector (slider + presets + remember) ───

  void _showSpeedSelector(
    BuildContext context,
    PlayerStateNotifier controller,
    double currentSpeed,
    String? mediaId,
  ) {
    const presets = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0];
    final prefs = AppScope.of(context).prefs;

    void apply(double speed) {
      controller.setSpeed(speed);
      if (prefs.rememberVideoSpeed && mediaId != null) {
        prefs.setVideoSpeed(mediaId, speed);
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          var sliderSpeed = currentSpeed;
          return SafeArea(
            child: Padding(
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
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          min: 0.25,
                          max: 3.0,
                          divisions: 55,
                          value: sliderSpeed.clamp(0.25, 3.0),
                          label: '${sliderSpeed.toStringAsFixed(2)}x',
                          activeColor: Theme.of(context).colorScheme.primary,
                          inactiveColor: Colors.white24,
                          onChanged: (value) {
                            sliderSpeed = value;
                            setSheetState(() {});
                            apply(value);
                          },
                        ),
                      ),
                      SizedBox(
                        width: 48,
                        child: Text(
                          '${sliderSpeed.toStringAsFixed(2)}x',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final speed in presets)
                        ChoiceChip(
                          label: Text('${speed}x'),
                          selected: (sliderSpeed - speed).abs() < 0.001,
                          labelStyle: const TextStyle(color: Colors.white),
                          selectedColor: Theme.of(context).colorScheme.primary,
                          backgroundColor: Colors.white12,
                          onSelected: (_) {
                            sliderSpeed = speed;
                            setSheetState(() {});
                            apply(speed);
                          },
                        ),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 24),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: Theme.of(context).colorScheme.primary,
                    title: const Text(
                      'Remember speed for this video',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Restored the next time this video opens',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    value: prefs.rememberVideoSpeed,
                    onChanged: (value) {
                      prefs.rememberVideoSpeed = value;
                      if (value && mediaId != null) {
                        prefs.setVideoSpeed(mediaId, sliderSpeed);
                      }
                      setSheetState(() {});
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Fit mode selector ───

  void _showFitSelector(
    BuildContext context,
    VideoFit currentFit,
    PlayerStateNotifier controller,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Aspect Ratio',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              for (final fit in VideoFit.values)
                ListTile(
                  leading: Icon(_fitIcon(fit), color: Colors.white),
                  title: Text(
                    fit.label,
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: fit == currentFit
                      ? Icon(Icons.check,
                          color: Theme.of(context).colorScheme.primary)
                      : null,
                  onTap: () {
                    controller.setVideoFit(fit);
                    onResetZoom();
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  IconData _fitIcon(VideoFit fit) => switch (fit) {
        VideoFit.contain => Icons.photo_size_select_actual_outlined,
        VideoFit.cover => Icons.photo_size_select_large_outlined,
        VideoFit.fill => Icons.straighten,
        VideoFit.natural => Icons.fullscreen,
      };

  // ─── More options (tracks/subtitles/queue/EQ/info + seek step + orientation) ───

  void _showMoreOptions(BuildContext context) {
    final rootContext = context;
    final prefs = AppScope.of(context).prefs;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Player Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    'Seek step',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      for (final step in const [5, 10, 15, 30, 60])
                        ChoiceChip(
                          label: Text('${step}s'),
                          selected: prefs.seekStepSeconds == step,
                          labelStyle: const TextStyle(color: Colors.white),
                          selectedColor: Theme.of(context).colorScheme.primary,
                          backgroundColor: Colors.white12,
                          onSelected: (_) {
                            prefs.seekStepSeconds = step;
                            setSheetState(() {});
                          },
                        ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24, height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    'Orientation',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                RadioGroup<VideoOrientation>(
                  groupValue: orientation,
                  onChanged: (value) {
                    if (value != null) onSetOrientation(value);
                    Navigator.pop(context);
                  },
                  child: Column(
                    children: [
                      for (final o in VideoOrientation.values)
                        RadioListTile<VideoOrientation>(
                          title: Text(
                            o.label,
                            style: const TextStyle(color: Colors.white),
                          ),
                          value: o,
                        ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24, height: 24),
                ListTile(
                  leading: const Icon(Icons.tune, color: Colors.white),
                  title: const Text('Tracks',
                      style: TextStyle(color: Colors.white)),
                  onTap: () => _launchSheet(
                    rootContext,
                    (sheetContext) => _buildSheetFrame(
                      sheetContext,
                      title: 'Tracks',
                      child: _TracksSheet(playback: _playbackOf(sheetContext)),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.closed_caption_outlined,
                      color: Colors.white),
                  title: const Text('Subtitles',
                      style: TextStyle(color: Colors.white)),
                  onTap: () => _launchSheet(
                    rootContext,
                    (sheetContext) => _buildSheetFrame(
                      sheetContext,
                      title: 'Subtitles',
                      child: _TracksSheet(
                        playback: _playbackOf(sheetContext),
                        focusSubtitles: true,
                      ),
                    ),
                  ),
                ),
                ListTile(
                  leading:
                      const Icon(Icons.queue_music, color: Colors.white),
                  title:
                      const Text('Queue', style: TextStyle(color: Colors.white)),
                  onTap: () => _launchSheet(
                    rootContext,
                    (sheetContext) => _buildSheetFrame(
                      sheetContext,
                      title: 'Queue',
                      child: _QueueSheet(
                        playback: _playbackOf(sheetContext),
                        autoNext: autoNext,
                        onAutoNextChanged: onAutoNextChanged,
                      ),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.equalizer, color: Colors.white),
                  title: const Text('Equalizer',
                      style: TextStyle(color: Colors.white)),
                  onTap: () => _launchSheet(
                    rootContext,
                    (sheetContext) => _buildSheetFrame(
                      sheetContext,
                      title: 'Equalizer',
                      child: _EqSheet(audio: _audioOf(sheetContext)),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline, color: Colors.white),
                  title: const Text('Media Info',
                      style: TextStyle(color: Colors.white)),
                  onTap: () => _launchSheet(
                    rootContext,
                    (sheetContext) => _buildSheetFrame(
                      sheetContext,
                      title: 'Media Info',
                      child: _MediaInfoSheet(
                        playback: _playbackOf(sheetContext),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PlaybackService _playbackOf(BuildContext context) =>
      AppScope.of(context).playback;

  AudioService _audioOf(BuildContext context) => AppScope.of(context).audio;

  /// Closes the settings sheet and opens a child sheet within the enhanced
  /// player's root context (which stays mounted while the sheets stack).
  void _launchSheet(
    BuildContext rootContext,
    Widget Function(BuildContext) builder,
  ) {
    Navigator.pop(rootContext);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!rootContext.mounted) return;
      onInteraction();
      showModalBottomSheet<void>(
        context: rootContext,
        backgroundColor: Colors.grey[900],
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (sheetContext) => builder(sheetContext),
      );
    });
  }

  Widget _buildSheetFrame(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: Colors.white54, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            Expanded(child: child),
          ],
        ),
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

// ─── Quick seek chip ───
class _SeekChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SeekChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.playerControls,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ─── Tracks sheet (audio/video/subtitle + external subtitle loader) ───
class _TracksSheet extends StatefulWidget {
  const _TracksSheet({
    required this.playback,
    this.focusSubtitles = false,
  });

  final PlaybackService playback;

  /// When true the subtitles section is shown first (used by the "Subtitles"
  /// menu entry).
  final bool focusSubtitles;

  @override
  State<_TracksSheet> createState() => _TracksSheetState();
}

class _TracksSheetState extends State<_TracksSheet> {
  @override
  Widget build(BuildContext context) {
    final playback = widget.playback;
    return AnimatedBuilder(
      animation: Listenable.merge([
        playback.subtitleTracks,
        playback.audioTracks,
        playback.videoTracks,
        playback.currentSubtitleTrack,
        playback.currentAudioTrack,
        playback.currentVideoTrack,
      ]),
      builder: (context, _) {
        final subtitles = _TrackSection(
          title: 'Subtitles',
          icon: Icons.closed_caption_outlined,
          tracks: playback.subtitleTracks.value,
          current: playback.currentSubtitleTrack.value,
          onSelect: playback.setSubtitleTrack,
          onDisable: playback.subtitleTracks.value.isEmpty
              ? null
              : playback.disableSubtitles,
          onAddExternal: _pickExternal,
        );
        final audio = _TrackSection(
          title: 'Audio',
          icon: Icons.audiotrack,
          tracks: playback.audioTracks.value,
          current: playback.currentAudioTrack.value,
          onSelect: playback.setAudioTrack,
        );
        final video = _TrackSection(
          title: 'Video',
          icon: Icons.videocam,
          tracks: playback.videoTracks.value,
          current: playback.currentVideoTrack.value,
          onSelect: playback.setVideoTrack,
        );

        final children = widget.focusSubtitles
            ? <Widget>[subtitles, audio, video]
            : <Widget>[audio, video, subtitles];
        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: children,
        );
      },
    );
  }

  Future<void> _pickExternal() async {
    final services = AppScope.of(context);
    final picked = await FilePicker.pickFile(
      dialogTitle: 'Select subtitle file',
      type: FileType.custom,
      allowedExtensions: const ['srt', 'vtt', 'ass', 'ssa'],
    );
    final path = picked?.path;
    if (picked == null || path == null) return;

    final playback = widget.playback;
    final mediaId = playback.currentMediaId.value;
    final parsed = await services.subtitle
        .loadFromFile(File(path), mediaId: mediaId);
    if (parsed == null || parsed.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not parse the selected subtitle file.'),
        ),
      );
      return;
    }

    await playback.setExternalSubtitles(
      Uri.file(path).toString(),
      title: picked.name,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Subtitle loaded.')),
    );
  }
}

class _TrackSection extends StatelessWidget {
  const _TrackSection({
    required this.title,
    required this.icon,
    required this.tracks,
    required this.current,
    required this.onSelect,
    this.onDisable,
    this.onAddExternal,
  });

  final String title;
  final IconData icon;
  final List<MediaTrack> tracks;
  final MediaTrack? current;
  final ValueChanged<MediaTrack> onSelect;
  final VoidCallback? onDisable;
  final VoidCallback? onAddExternal;

  @override
  Widget build(BuildContext context) {
    final empty = tracks.isEmpty && onDisable == null && onAddExternal == null;
    if (empty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Row(
            children: [
              Icon(icon, color: Colors.white54, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (tracks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'No tracks found.',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          )
        else
          for (final track in tracks) _buildTrackTile(context, track),
        if (onDisable != null)
          TextButton(
            onPressed: onDisable,
            style: TextButton.styleFrom(foregroundColor: Colors.white54),
            child: const Text('Disable subtitles'),
          ),
        if (onAddExternal != null)
          ListTile(
            dense: true,
            leading: const Icon(Icons.add, color: Colors.white54),
            title: const Text(
              'Add external subtitle file (.srt / .vtt / .ass)',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            onTap: onAddExternal,
          ),
      ],
    );
  }

  Widget _buildTrackTile(BuildContext context, MediaTrack track) {
    final selected = current == track;
    final details = [
      if (track.language != null) track.language!,
      if (track.codec != null) track.codec!,
    ].join(' · ');
    return ListTile(
      dense: true,
      leading: Icon(
        selected ? Icons.check_circle : Icons.radio_button_unchecked,
        color: selected
            ? Theme.of(context).colorScheme.primary
            : Colors.white38,
        size: 20,
      ),
      title: Text(
        track.label.isEmpty ? 'Track ${track.id}' : track.label,
        style: TextStyle(
          color: selected ? Colors.white : Colors.white70,
          fontSize: 14,
        ),
      ),
      subtitle: details.isEmpty
          ? null
          : Text(
              details,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
      onTap: () => onSelect(track),
    );
  }
}

// ─── Queue sheet (reorder / remove / jump / clear / auto-next) ───
class _QueueSheet extends StatefulWidget {
  const _QueueSheet({
    required this.playback,
    required this.autoNext,
    required this.onAutoNextChanged,
  });

  final PlaybackService playback;
  final bool autoNext;
  final ValueChanged<bool> onAutoNextChanged;

  @override
  State<_QueueSheet> createState() => _QueueSheetState();
}

class _QueueSheetState extends State<_QueueSheet> {
  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Clear queue?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This stops the current playback.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.playback.clearQueue();
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final playback = widget.playback;
    return AnimatedBuilder(
      animation: Listenable.merge([playback.queue, playback.currentIndex]),
      builder: (context, _) {
        final items = playback.queueItems;
        final index = playback.currentIndex.value;
        final primary = Theme.of(context).colorScheme.primary;
        return Column(
          children: [
            Expanded(
              child: items.isEmpty
                  ? const Center(
                      child: Text(
                        'Queue is empty',
                        style: TextStyle(color: Colors.white38),
                      ),
                    )
                  : ReorderableListView.builder(
                      buildDefaultDragHandles: true,
                      itemCount: items.length,
                      onReorderItem: (oldIndex, newIndex) {
                        playback.reorderQueue(oldIndex, newIndex);
                      },
                      itemBuilder: (context, i) {
                        final item = items[i];
                        final isCurrent = i == index;
                        return ListTile(
                          key: ValueKey('${item.id}:$i'),
                          dense: true,
                          leading: Icon(
                            isCurrent
                                ? Icons.graphic_eq
                                : Icons.music_note,
                            color: isCurrent ? primary : Colors.white38,
                          ),
                          title: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isCurrent
                                  ? Colors.white
                                  : Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          trailing: IconButton(
                            tooltip: 'Remove',
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              color: Colors.white38,
                              size: 20,
                            ),
                            onPressed: () => playback.removeFromQueue(i),
                          ),
                          onTap: () {
                            playback.jumpTo(i);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
            const Divider(color: Colors.white24, height: 1),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              activeThumbColor: primary,
              title: const Text(
                'Auto-next',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              subtitle: const Text(
                'Play the next item when the current one ends',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              value: widget.autoNext,
              onChanged: widget.onAutoNextChanged,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: items.isEmpty ? null : _confirmClear,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                  ),
                  child: const Text('Clear Queue'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Quick equalizer sheet (reuses AudioService DSP config) ───
class _EqSheet extends StatelessWidget {
  const _EqSheet({required this.audio});

  final AudioService audio;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: audio,
      builder: (context, _) {
        final eq = audio.eq;
        final primary = Theme.of(context).colorScheme.primary;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: primary,
              title: const Text(
                'Enable equalizer',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              value: eq.enabled,
              onChanged: (v) => audio.setEq(eq.copyWith(enabled: v)),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: eq.preampDb,
                    min: -20,
                    max: 20,
                    divisions: 80,
                    label: '${eq.preampDb.toStringAsFixed(1)} dB',
                    activeColor: primary,
                    inactiveColor: Colors.white24,
                    onChanged: eq.enabled
                        ? (v) => audio.setEq(eq.copyWith(preampDb: v))
                        : null,
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Text(
                    'Preamp: ${eq.preampDb.toStringAsFixed(1)} dB',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  'Bands (${eq.bands.length})',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () =>
                      audio.setEq(eq.addBand(const EqBand(frequencyHz: 1000))),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add band'),
                  style: TextButton.styleFrom(foregroundColor: primary),
                ),
              ],
            ),
            if (eq.bands.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'No bands yet. Add one to shape the sound.',
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ),
              ),
            for (var i = 0; i < eq.bands.length; i++)
              _EqBandRow(
                band: eq.bands[i],
                enabled: eq.enabled,
                onChanged: (band) {
                  final bands = List<EqBand>.of(eq.bands);
                  bands[i] = band;
                  audio.setEq(eq.copyWith(bands: bands));
                },
                onRemove: () => audio.setEq(eq.removeBandAt(i)),
              ),
          ],
        );
      },
    );
  }
}

class _EqBandRow extends StatelessWidget {
  const _EqBandRow({
    required this.band,
    required this.enabled,
    required this.onChanged,
    required this.onRemove,
  });

  final EqBand band;
  final bool enabled;
  final ValueChanged<EqBand> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${band.frequencyHz.round()} Hz',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
            Text(
              '${band.gainDb >= 0 ? '+' : ''}${band.gainDb.toStringAsFixed(1)} dB',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white38, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onRemove,
            ),
          ],
        ),
        Slider(
          value: band.gainDb,
          min: -20,
          max: 20,
          divisions: 80,
          activeColor: Theme.of(context).colorScheme.primary,
          inactiveColor: Colors.white24,
          onChanged: enabled
              ? (v) => onChanged(band.copyWith(gainDb: v))
              : null,
        ),
      ],
    );
  }
}

// ─── Media info sheet ───
class _MediaInfoSheet extends StatelessWidget {
  const _MediaInfoSheet({required this.playback});

  final PlaybackService playback;

  @override
  Widget build(BuildContext context) {
    final item = playback.currentItem;
    final services = AppScope.of(context);

    final future = item == null
        ? Future<ExtendedMediaInfo?>.value(null)
        : services.media.byId(item.id).then(
            (row) async => row == null
                ? null
                : await const MediaInfoService().inspect(
                    row: row,
                    repository: services.media,
                    playbackDuration: playback.duration.value,
                    liveResolution: playback.videoWidth.value != null &&
                            playback.videoHeight.value != null
                        ? '${playback.videoWidth.value} × '
                            '${playback.videoHeight.value}'
                        : null,
                  ),
          );

    return AnimatedBuilder(
      animation: Listenable.merge([
        playback.duration,
        playback.rate,
        playback.videoWidth,
        playback.videoHeight,
        playback.currentAudioTrack,
        playback.currentSubtitleTrack,
        playback.videoTracks,
        playback.audioTracks,
        playback.subtitleTracks,
      ]),
      builder: (context, _) {
        return FutureBuilder<ExtendedMediaInfo?>(
          future: future,
          builder: (context, snapshot) {
            final info = snapshot.data;
            final liveResolution = playback.videoWidth.value != null &&
                    playback.videoHeight.value != null
                ? '${playback.videoWidth.value} × '
                    '${playback.videoHeight.value}'
                : null;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _infoRow(context, 'Title', item?.title ?? '—'),
                _infoRow(
                  context,
                  'Type',
                  item == null
                      ? '—'
                      : item.type == MediaType.video
                          ? 'Video'
                          : 'Audio',
                ),
                _infoRow(
                  context,
                  'Duration',
                  Fmt.duration(playback.duration.value),
                ),
                _infoRow(
                  context,
                  'Resolution',
                  liveResolution ??
                      info?.resolution ??
                      '${playback.videoWidth.value ?? '?'} × '
                          '${playback.videoHeight.value ?? '?'}',
                ),
                _infoRow(
                  context,
                  'Speed',
                  '${playback.rate.value.toStringAsFixed(2)}×',
                ),
                if (info != null) ...[
                  _infoRow(context, 'File size', Fmt.bytes(info.fileSize)),
                  _infoRow(context, 'Format', info.format ?? '—'),
                  _infoRow(
                    context,
                    'Bitrate',
                    info.bitrate == null
                        ? '—'
                        : '${(info.bitrate! / 1000).toStringAsFixed(0)} kbps',
                  ),
                  _infoRow(
                    context,
                    'Sample rate',
                    info.sampleRate == null ? '—' : '${info.sampleRate} Hz',
                  ),
                  _infoRow(context, 'Added', Fmt.date(info.createdAt)),
                  _infoRow(context, 'Modified', Fmt.date(info.modifiedAt)),
                  _infoRow(context, 'Play count', '${info.playCount}'),
                  _infoRow(context, 'Last played', Fmt.date(info.lastPlayedAt)),
                ],
                if (snapshot.hasError)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Some details unavailable.',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 8),
                const Text(
                  'Available tracks',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                _infoRow(context, 'Video', _trackNames(playback.videoTracks.value)),
                _infoRow(context, 'Audio', _trackNames(playback.audioTracks.value)),
                _infoRow(
                  context,
                  'Subtitle',
                  _trackNames(playback.subtitleTracks.value),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _trackNames(List<MediaTrack> tracks) {
    if (tracks.isEmpty) return '—';
    return tracks.map((t) => t.label.isEmpty ? t.id : t.label).join(', ');
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}