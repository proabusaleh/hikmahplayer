import 'package:flutter/material.dart';

import '../../../../shared/utils/format.dart';
import '../../domain/models/storage_stats.dart';

/// Compact storage analysis card (total size, file count, codec distribution).
class StorageStatsCard extends StatelessWidget {
  const StorageStatsCard({super.key, required this.stats});

  final StorageStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Library storage', style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Metric(
                    value: Fmt.bytes(stats.totalBytes),
                    label: 'Total size',
                  ),
                ),
                Expanded(
                  child: _Metric(
                    value: '${stats.totalFiles}',
                    label: 'Files',
                  ),
                ),
                Expanded(
                  child: _Metric(
                    value: stats.dominantResolution ?? '—',
                    label: 'Best quality',
                  ),
                ),
              ],
            ),
            if (stats.byCodec.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 4),
              Text('Codecs', style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
              for (final entry in stats.byCodec.entries.take(5))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.key.isEmpty ? 'unknown' : entry.key,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${entry.value.count} files · ${Fmt.bytes(entry.value.totalBytes)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
