import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../presentation/providers/history_provider.dart';
import '../../../../shared/utils/format.dart';
import '../../../../shared/widgets/artwork_widget.dart';
import '../../domain/models/watch_stats.dart';
import '../providers/stats_provider.dart';

/// Privacy-friendly local analytics: watch/listen time, completion rates and
/// top media. All data is computed from the on-device history.
class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  StatsPeriod _period = StatsPeriod.week;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final stats = ref.watch(statisticsProvider(_period)).valueOrNull ??
        WatchStats.empty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics & Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear analytics',
            onPressed: () => ref.read(playHistoryProvider.notifier).clear(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _PrivacyBanner(),
          const SizedBox(height: 16),
          SegmentedButton<StatsPeriod>(
            segments: [
              for (final period in StatsPeriod.values)
                ButtonSegment(value: period, label: Text(period.label)),
            ],
            selected: {_period},
            onSelectionChanged: (selection) =>
                setState(() => _period = selection.first),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Watch time',
                  value: _hours(stats.videoWatchedMs),
                  icon: Icons.videocam_outlined,
                  color: primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  label: 'Listen time',
                  value: _hours(stats.audioWatchedMs),
                  icon: Icons.headphones_outlined,
                  color: Colors.lightBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Completion',
                  value: '${(stats.completionRate * 100).toStringAsFixed(0)}%',
                  icon: Icons.check_circle_outline,
                  color: Colors.orangeAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  label: 'Sessions',
                  value: '${stats.sessionCount}',
                  icon: Icons.history,
                  color: Colors.purpleAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionTitle('Time by window'),
          const SizedBox(height: 4),
          const _WindowTile('Today', StatsPeriod.day),
          const _WindowTile('Past 7 days', StatsPeriod.week),
          const _WindowTile('Past 30 days', StatsPeriod.month),
          const _WindowTile('Past 365 days', StatsPeriod.year),
          const SizedBox(height: 24),
          const _SectionTitle('Most played videos'),
          const SizedBox(height: 4),
          _MostPlayedList(entries: stats.topVideos, isVideo: true),
          const SizedBox(height: 16),
          const _SectionTitle('Most played audio'),
          const SizedBox(height: 4),
          _MostPlayedList(entries: stats.topAudio, isVideo: false),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  static String _hours(int ms) {
    final hours = ms / Duration.millisecondsPerHour;
    return '${hours.toStringAsFixed(1)} hrs';
  }
}

class _PrivacyBanner extends StatelessWidget {
  const _PrivacyBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, color: Colors.green),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '100% private — all analytics stay on this device.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context)
          .textTheme
          .titleSmall
          ?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _WindowTile extends ConsumerWidget {
  const _WindowTile(this.label, this.period);
  final String label;
  final StatsPeriod period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats =
        ref.watch(statisticsProvider(period)).valueOrNull ?? WatchStats.empty;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: Text(
        _hours(stats.totalWatchedMs),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  static String _hours(int ms) {
    final hours = ms / Duration.millisecondsPerHour;
    return '${hours.toStringAsFixed(1)} hrs';
  }
}

class _MostPlayedList extends StatelessWidget {
  const _MostPlayedList({required this.entries, required this.isVideo});
  final List<TopPlayedEntry> entries;
  final bool isVideo;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Text(
        'Nothing played yet',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    return Column(
      children: [
        for (final entry in entries)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: ArtworkWidget(
              title: entry.title,
              path: entry.artworkPath,
              size: 40,
              isVideo: isVideo,
            ),
            title: Text(
              entry.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${entry.plays} play${entry.plays == 1 ? '' : 's'} · '
              '${Fmt.duration(Duration(milliseconds: entry.watchedMs))} watched',
            ),
          ),
      ],
    );
  }
}