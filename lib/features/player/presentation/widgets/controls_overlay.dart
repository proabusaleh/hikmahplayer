import 'package:flutter/material.dart' hide RepeatMode;

import '../../../../core/services/playback_service.dart';
import '../../../../shared/utils/format.dart';
import '../../domain/models/media_track.dart';
import '../../domain/models/playback_settings.dart';
import '../providers/playback_provider.dart';
import 'seek_bar.dart';
import 'speed_selector.dart';
import 'timeline_preview.dart';

/// Bottom transport controls for the player: seek bar, timeline preview,
/// play/pause/next/previous, repeat, shuffle, volume, speed and the options
/// sheet (tracks, chapters, A-B loop, bookmarks, sleep timer).
class ControlsOverlay extends StatefulWidget {
  const ControlsOverlay({
    super.key,
    required this.controller,
    required this.playback,
  });

  final PlaybackController controller;
  final PlaybackService playback;

  @override
  State<ControlsOverlay> createState() => _ControlsOverlayState();
}

class _ControlsOverlayState extends State<ControlsOverlay> {
  Duration? _preview;

  @override
  Widget build(BuildContext context) {
    final playback = widget.playback;
    return AnimatedBuilder(
      animation: Listenable.merge([
        playback.isPlaying,
        playback.repeatMode,
        playback.shuffleEnabled,
        playback.volume,
        playback.rate,
        widget.controller,
      ]),
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_preview != null)
              TimelinePreview(playback: playback, previewPosition: _preview),
            PlayerSeekBar(
              playback: playback,
              onPreview: (d) => setState(() => _preview = d),
              onCommit: (d) {
                setState(() => _preview = null);
                playback.seek(d);
              },
            ),
            Row(
              children: [
                IconButton(
                  tooltip: 'Repeat',
                  onPressed: () {
                    final next = switch (playback.repeatMode.value) {
                      RepeatMode.off => RepeatMode.all,
                      RepeatMode.all => RepeatMode.one,
                      RepeatMode.one => RepeatMode.off,
                    };
                    playback.setRepeatMode(next);
                  },
                  icon: Icon(
                    playback.repeatMode.value == RepeatMode.one
                        ? Icons.repeat_one
                        : Icons.repeat,
                    color: playback.repeatMode.value == RepeatMode.off
                        ? Colors.white38
                        : null,
                  ),
                ),
                IconButton(
                  tooltip: 'Shuffle',
                  onPressed: () => playback.toggleShuffle(),
                  icon: Icon(
                    Icons.shuffle,
                    color: playback.shuffleEnabled.value
                        ? null
                        : Colors.white38,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Previous',
                  onPressed: () => playback.previous(),
                  iconSize: 30,
                  icon: const Icon(Icons.skip_previous),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: playback.isPlaying,
                  builder: (context, isPlaying, _) {
                    return IconButton.filled(
                      tooltip: isPlaying ? 'Pause' : 'Play',
                      onPressed: () => widget.controller.togglePlay(),
                      iconSize: 38,
                      padding: const EdgeInsets.all(12),
                      icon: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                      ),
                    );
                  },
                ),
                IconButton(
                  tooltip: 'Next',
                  onPressed: () => playback.next(),
                  iconSize: 30,
                  icon: const Icon(Icons.skip_next),
                ),
                const Spacer(),
                SpeedSelector(
                  currentRate: playback.rate.value,
                  onRateSelected: (rate) => widget.controller.setRate(rate),
                ),
                _VolumeButton(playback: playback),
                IconButton(
                  tooltip: 'Options',
                  onPressed: () => _showOptionsSheet(context),
                  icon: const Icon(Icons.tune),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showOptionsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _PlayerOptionsSheet(
        controller: widget.controller,
        playback: widget.playback,
      ),
    );
  }
}

class _VolumeButton extends StatelessWidget {
  const _VolumeButton({required this.playback});

  final PlaybackService playback;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: playback.volume,
      builder: (context, volume, _) {
        return PopupMenuButton<double>(
          tooltip: 'Volume',
          icon: Icon(volume <= 0.001
              ? Icons.volume_off
              : volume < 0.5
                  ? Icons.volume_down
                  : Icons.volume_up),
          itemBuilder: (context) => [
            PopupMenuItem<double>(
              height: 56,
              child: StatefulBuilder(
                builder: (context, setState) => SizedBox(
                  width: 160,
                  child: Slider(
                    value: volume,
                    onChanged: (v) {
                      playback.setVolume(v);
                      setState(() {});
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PlayerOptionsSheet extends StatefulWidget {
  const _PlayerOptionsSheet({
    required this.controller,
    required this.playback,
  });

  final PlaybackController controller;
  final PlaybackService playback;

  @override
  State<_PlayerOptionsSheet> createState() => _PlayerOptionsSheetState();
}

class _PlayerOptionsSheetState extends State<_PlayerOptionsSheet> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final playback = widget.playback;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('Chapters'), icon: Icon(Icons.list)),
                  ButtonSegment(value: 1, label: Text('Tracks'), icon: Icon(Icons.subtitles)),
                  ButtonSegment(value: 2, label: Text('A-B'), icon: Icon(Icons.repeat)),
                  ButtonSegment(value: 3, label: Text('Notes'), icon: Icon(Icons.bookmark)),
                ],
                selected: {_tab},
                onSelectionChanged: (s) => setState(() => _tab = s.first),
                showSelectedIcon: false,
              ),
            ),
            const Divider(),
            Expanded(
              child: switch (_tab) {
                0 => _ChaptersTab(playback: playback),
                1 => _TracksTab(playback: playback),
                2 => _AbLoopTab(controller: widget.controller),
                3 => _NotesTab(controller: widget.controller),
                _ => const SizedBox.shrink(),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ChaptersTab extends StatelessWidget {
  const _ChaptersTab({required this.playback});

  final PlaybackService playback;

  @override
  Widget build(BuildContext context) {
    final chapters = playback.currentItem?.chapters ?? const [];
    if (chapters.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No chapters for this media yet.\nGenerate them from the Learn tab.'),
        ),
      );
    }
    return ListView.builder(
      itemCount: chapters.length,
      itemBuilder: (context, i) {
        final chapter = chapters[i];
        return ListTile(
          leading: const Icon(Icons.menu_book),
          title: Text(chapter.title),
          subtitle: Text(Fmt.duration(chapter.start)),
          onTap: () => playback.seek(chapter.start),
        );
      },
    );
  }
}

class _TracksTab extends StatelessWidget {
  const _TracksTab({required this.playback});

  final PlaybackService playback;

  @override
  Widget build(BuildContext context) {
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
        return ListView(
          children: [
            _TrackSection(
              title: 'Subtitles',
              tracks: playback.subtitleTracks.value,
              current: playback.currentSubtitleTrack.value,
              onSelect: (t) {
                playback.setSubtitleTrack(t);
                Navigator.pop(context);
              },
              onDisable: playback.subtitleTracks.value.isEmpty
                  ? null
                  : () {
                      playback.disableSubtitles();
                      Navigator.pop(context);
                    },
            ),
            _TrackSection(
              title: 'Audio',
              tracks: playback.audioTracks.value,
              current: playback.currentAudioTrack.value,
              onSelect: (t) {
                playback.setAudioTrack(t);
                Navigator.pop(context);
              },
            ),
            _TrackSection(
              title: 'Video',
              tracks: playback.videoTracks.value,
              current: playback.currentVideoTrack.value,
              onSelect: (t) {
                playback.setVideoTrack(t);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}

class _TrackSection extends StatelessWidget {
  const _TrackSection({
    required this.title,
    required this.tracks,
    required this.current,
    required this.onSelect,
    this.onDisable,
  });

  final String title;
  final List<MediaTrack> tracks;
  final MediaTrack? current;
  final ValueChanged<MediaTrack> onSelect;
  final VoidCallback? onDisable;

  @override
  Widget build(BuildContext context) {
    if (tracks.isEmpty && onDisable == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(title, style: Theme.of(context).textTheme.labelLarge),
        ),
        if (tracks.isEmpty)
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('No tracks available'),
            onTap: onDisable,
          )
        else
          RadioGroup<MediaTrack>(
            groupValue: current,
            onChanged: (t) {
              if (t != null) onSelect(t);
            },
            child: Column(
              children: [
                for (final track in tracks)
                  RadioListTile<MediaTrack>(
                    value: track,
                    title: Text(
                        track.label.isEmpty ? 'Track ${track.id}' : track.label),
                    subtitle: Text([
                      if (track.language != null) track.language!,
                      if (track.codec != null) track.codec!,
                    ].join(' · ')),
                  ),
              ],
            ),
          ),
        if (onDisable != null)
          TextButton(onPressed: onDisable, child: const Text('Disable subtitles')),
      ],
    );
  }
}

class _AbLoopTab extends StatelessWidget {
  const _AbLoopTab({required this.controller});

  final PlaybackController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final position = controller.playback.position.value;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              leading: const Icon(Icons.flag),
              title: const Text('Set point A'),
              subtitle: Text('Current: ${Fmt.duration(position)}'),
              trailing: controller.aPoint != null
                  ? Text(Fmt.duration(controller.aPoint))
                  : null,
              onTap: () => controller.setAPoint(position),
            ),
            ListTile(
              leading: const Icon(Icons.flag_circle),
              title: const Text('Set point B'),
              subtitle: Text('Current: ${Fmt.duration(position)}'),
              trailing: controller.bPoint != null
                  ? Text(Fmt.duration(controller.bPoint))
                  : null,
              enabled: controller.aPoint != null,
              onTap: () => controller.setBPoint(position),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Loop A-B'),
              subtitle: Text(
                controller.loopActive
                    ? '${Fmt.duration(controller.aPoint)} – ${Fmt.duration(controller.bPoint)}'
                    : 'Set point A then point B to loop',
              ),
              value: controller.loopActive,
              onChanged: (v) {
                if (v) {
                  final p = controller.playback.position.value;
                  if (controller.aPoint == null) {
                    controller.setAPoint(p);
                  } else if (controller.bPoint == null) {
                    controller.setBPoint(p);
                  }
                } else {
                  controller.clearLoop();
                }
              },
            ),
            const SizedBox(height: 16),
            Text('Sleep timer', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final (label, duration) in [
                  ('Off', null),
                  ('10 min', const Duration(minutes: 10)),
                  ('30 min', const Duration(minutes: 30)),
                  ('1 hour', const Duration(hours: 1)),
                  ('End of item', const Duration(hours: 99)),
                ])
                  ChoiceChip(
                    label: Text(label),
                    selected: _isSelected(label),
                    onSelected: (_) => controller.setSleepTimer(duration),
                  ),
              ],
            ),
            if (controller.sleepRemaining != null) ...[
              const SizedBox(height: 8),
              Text(
                'Stopping in ${Fmt.duration(controller.sleepRemaining)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        );
      },
    );
  }

  bool _isSelected(String label) {
    if (label == 'Off') return controller.sleepRemaining == null;
    if (controller.sleepRemaining == null) return false;
    final minutes = controller.sleepRemaining!.inMinutes;
    return label == '10 min' && minutes <= 10 ||
        label == '30 min' && minutes <= 30 ||
        label == '1 hour' && minutes > 30;
  }
}

class _NotesTab extends StatelessWidget {
  const _NotesTab({required this.controller});

  final PlaybackController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final bookmarks = controller.bookmarks;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: FilledButton.icon(
                onPressed: () => controller.addBookmark('Moment'),
                icon: const Icon(Icons.bookmark_add),
                label: const Text('Bookmark current position'),
              ),
            ),
            Expanded(
              child: bookmarks.isEmpty
                  ? const Center(child: Text('No bookmarks yet'))
                  : ListView.builder(
                      itemCount: bookmarks.length,
                      itemBuilder: (context, i) {
                        final b = bookmarks[i];
                        return ListTile(
                          leading: Icon(Icons.bookmark, color: Color(b.colorValue)),
                          title: Text(b.label),
                          subtitle: Text(Fmt.duration(b.position)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => controller.removeBookmark(b.id),
                          ),
                          onTap: () => controller.playback.seek(b.position),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
