import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../core/services/developer_service.dart';
import '../../../developer/domain/models/playback_analytics.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dev = AppScope.of(context).developer;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Playback Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_chart),
            tooltip: 'Add sample data',
            onPressed: () => _addSampleData(dev),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: dev,
        builder: (context, _) {
          final summary = dev.analyticsSummary;
          final stats = dev.mediaStats;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SummaryCard(summary: summary),
              const SizedBox(height: 16),
              if (stats.isEmpty)
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.analytics,
                          size: 48,
                          color: Theme.of(context).colorScheme.outline),
                      const SizedBox(height: 8),
                      Text('No data yet',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        'Play some media to see analytics.',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.outline),
                      ),
                    ],
                  ),
                )
              else ...[
                Text('Per-Media Stats',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final s in stats)
                  _StatsTile(stats: s),
              ],
              if (dev.recentSkips.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Recent Skips',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final skip in dev.recentSkips.take(20))
                  ListTile(
                    dense: true,
                    leading: Icon(
                      _skipIcon(skip.type),
                      size: 20,
                      color: _skipColor(skip.type),
                    ),
                    title: Text(
                      '${_formatPos(skip.fromPositionSeconds)} → ${_formatPos(skip.toPositionSeconds)}',
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                    subtitle: Text(skip.type.name),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  void _addSampleData(DeveloperService dev) {
    dev.recordPlay('media-1', duration: const Duration(minutes: 45));
    dev.recordPlay('media-1', duration: const Duration(minutes: 50));
    dev.recordPlay('media-2', duration: const Duration(minutes: 30));
    dev.recordPlay('media-3', duration: const Duration(minutes: 15));
    dev.recordPlay('media-3', duration: const Duration(minutes: 20));
    dev.recordPlay('media-3', duration: const Duration(minutes: 25));
    dev.recordPlay('media-4', duration: const Duration(minutes: 90));
  }

  static String _formatPos(double seconds) {
    final m = (seconds / 60).floor();
    final s = (seconds % 60).round();
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  static IconData _skipIcon(SkipEventType type) {
    return switch (type) {
      SkipEventType.skip => Icons.skip_next,
      SkipEventType.rewind => Icons.replay,
      SkipEventType.fastForward => Icons.fast_forward,
      SkipEventType.slowDown => Icons.slow_motion_video,
    };
  }

  static Color _skipColor(SkipEventType type) {
    return switch (type) {
      SkipEventType.skip => Colors.orange,
      SkipEventType.rewind => Colors.blue,
      SkipEventType.fastForward => Colors.green,
      SkipEventType.slowDown => Colors.purple,
    };
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final PlaybackAnalyticsSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Summary', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MiniStat(value: '${summary.totalPlays}', label: 'Plays'),
                _MiniStat(value: summary.formattedWatchTime, label: 'Watched'),
                _MiniStat(value: '${summary.uniqueMedia}', label: 'Media'),
                _MiniStat(
                  value: '${(summary.averageCompletionRate * 100).round()}%',
                  label: 'Complete',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MiniStat(value: '${summary.totalSkips}', label: 'Skips'),
                _MiniStat(value: '${summary.totalRewinds}', label: 'Rewinds'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _StatsTile extends StatelessWidget {
  const _StatsTile({required this.stats});

  final MediaPlaybackStats stats;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text('${stats.playCount}')),
        title: Text(stats.mediaId),
        subtitle: Text(
          '${_formatDuration(stats.totalWatchTime)} total · '
          '${(stats.completionRate * 100).round()}% complete',
        ),
      ),
    );
  }

  static String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}
