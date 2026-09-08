import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/video_filter.dart';
import '../../../providers/media_provider.dart' show videosListProvider;
import 'video_library_provider.dart';

/// Bottom sheet to configure video library filters.
Future<void> showVideoFilterSheet(BuildContext context, {required WidgetRef ref}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _VideoFilterSheet(ref: ref),
  );
}

class _VideoFilterSheet extends ConsumerStatefulWidget {
  const _VideoFilterSheet({required this.ref});

  final WidgetRef ref;

  @override
  ConsumerState<_VideoFilterSheet> createState() => _VideoFilterSheetState();
}

class _VideoFilterSheetState extends ConsumerState<_VideoFilterSheet> {
  late VideoDurationFilter? _duration;
  late VideoResolutionFilter? _resolution;
  late VideoTagFilter? _tag;

  @override
  void initState() {
    super.initState();
    final current = widget.ref.read(videoFilterProvider);
    _duration = current.duration;
    _resolution = current.resolution;
    _tag = current.tag;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeCount = ref.watch(videoFilterCountProvider);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Row(
              children: [
                Icon(Icons.filter_list_rounded, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Filter Videos',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                if (activeCount > 0)
                  TextButton(
                    onPressed: () {
                      ref.read(videoFilterProvider.notifier).state = const VideoLibraryFilter();
                      Navigator.pop(context);
                    },
                    child: const Text('Clear all'),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Duration section
          _SectionHeader(label: 'Duration'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final d in VideoDurationFilter.values)
                  _FilterChip(
                    label: switch (d) {
                      VideoDurationFilter.short => '< 5 min',
                      VideoDurationFilter.medium => '5-20 min',
                      VideoDurationFilter.long => '> 20 min',
                    },
                    selected: _duration == d,
                    onTap: () => setState(() => _duration = _duration == d ? null : d),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Resolution section
          _SectionHeader(label: 'Resolution'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final r in VideoResolutionFilter.values)
                  _FilterChip(
                    label: switch (r) {
                      VideoResolutionFilter.sd => 'SD',
                      VideoResolutionFilter.hd => 'HD',
                      VideoResolutionFilter.fullHd => 'FHD',
                      VideoResolutionFilter.fourK => '4K',
                      VideoResolutionFilter.unknown => 'Unknown',
                    },
                    selected: _resolution == r,
                    onTap: () => setState(() => _resolution = _resolution == r ? null : r),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tag section
          _SectionHeader(label: 'Tags'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in VideoTagFilter.values)
                  _FilterChip(
                    label: switch (t) {
                      VideoTagFilter.favorite => 'Favorite',
                      VideoTagFilter.noTag => 'No Tag',
                    },
                    selected: _tag == t,
                    onTap: () => setState(() => _tag = _tag == t ? null : t),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Preview count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _FilterPreview(ref: ref, duration: _duration, resolution: _resolution, tag: _tag),
          ),
          const SizedBox(height: 12),

          // Apply button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  ref.read(videoFilterProvider.notifier).state = VideoLibraryFilter(
                    duration: _duration,
                    resolution: _resolution,
                    tag: _tag,
                  );
                  Navigator.pop(context);
                },
                child: const Text('Apply Filters'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.15)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _FilterPreview extends ConsumerWidget {
  const _FilterPreview({
    required this.ref,
    required this.duration,
    required this.resolution,
    required this.tag,
  });

  final WidgetRef ref;
  final VideoDurationFilter? duration;
  final VideoResolutionFilter? resolution;
  final VideoTagFilter? tag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = _countMatches(ref, duration, resolution, tag);
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count video${count == 1 ? '' : 's'} match',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  int _countMatches(WidgetRef ref, VideoDurationFilter? d, VideoResolutionFilter? r, VideoTagFilter? t) {
    final videos = ref.read(videosListProvider);
    final filter = VideoLibraryFilter(duration: d, resolution: r, tag: t);
    return videos.where((v) => _match(v, filter)).length;
  }

  bool _match(dynamic v, VideoLibraryFilter filter) {
    if (filter.duration != null) {
      final minutes = v.durationMs / 60000;
      final match = switch (filter.duration!) {
        VideoDurationFilter.short => minutes < 5,
        VideoDurationFilter.medium => minutes >= 5 && minutes < 20,
        VideoDurationFilter.long => minutes >= 20,
      };
      if (!match) return false;
    }
    if (filter.resolution != null) {
      if (classifyResolution(v.height) != filter.resolution) return false;
    }
    if (filter.tag != null) {
      final match = switch (filter.tag!) {
        VideoTagFilter.favorite => v.isFavorite,
        VideoTagFilter.noTag => !v.isFavorite,
      };
      if (!match) return false;
    }
    return true;
  }
}
