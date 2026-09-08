import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/utils/format.dart';
import '../../../../shared/widgets/artwork_widget.dart';
import '../../../../core/storage/app_database.dart';
import '../../../../core/storage/media_type.dart';
import '../../domain/models/storage_scan_result.dart';
import '../providers/storage_provider.dart';

/// Storage overview + smart cleanup over the local library.
class StorageManagerScreen extends ConsumerWidget {
  const StorageManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scan = ref.watch(storageScanProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Rescan',
            onPressed: () => ref.read(storageScanProvider.notifier).run(),
          ),
        ],
      ),
      body: switch (scan) {
        AsyncValue(:final isLoading) when isLoading => const Center(
            child: CircularProgressIndicator(),
          ),
        AsyncError(:final error) => Center(
            child: Text('Failed to scan: $error'),
          ),
        _ => _buildBody(context, ref, scan.valueOrNull ?? StorageScanResult.empty),
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    StorageScanResult result,
  ) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _OverviewCard(result: result, color: primary),
        const SizedBox(height: 16),
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          icon: const Icon(Icons.cleaning_services),
          label: const Text('Smart cleanup (caches & empty folders)'),
          onPressed: () async {
            await ref.read(storageScanProvider.notifier).smartCleanup();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Smart cleanup completed')),
              );
            }
          },
        ),
        const SizedBox(height: 24),
        Text(
          'Breakdown',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        _BreakdownTile(
          icon: Icons.videocam_outlined,
          label: 'Videos',
          value: Fmt.bytes(result.videoBytes),
          color: Colors.lightBlue,
        ),
        _BreakdownTile(
          icon: Icons.music_note_outlined,
          label: 'Music',
          value: Fmt.bytes(result.musicBytes),
          color: Colors.green,
        ),
        _BreakdownTile(
          icon: Icons.image_outlined,
          label: 'Thumbnail cache',
          value: Fmt.bytes(result.thumbnailBytes),
          color: Colors.orange,
        ),
        _BreakdownTile(
          icon: Icons.cached,
          label: 'App cache (temp & waveforms)',
          value: Fmt.bytes(result.cacheBytes),
          color: Colors.redAccent,
        ),
        const SizedBox(height: 24),
        Text(
          'Largest files',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        _FileList(
          items: result.largestFiles,
          empty: 'No large files',
          subtitle: (item) => Fmt.bytes(item.fileSize),
        ),
        const SizedBox(height: 24),
        Text(
          'Possible duplicates',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        if (result.duplicateGroups.isEmpty)
          Text('No duplicates found', style: theme.textTheme.bodySmall)
        else
          for (final (_, group) in result.duplicateGroups.indexed)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.copy_all_outlined),
              title: Text(group.first.fileName,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                '${group.length} copies · ${Fmt.bytes(group.first.fileSize)} each',
              ),
            ),
        const SizedBox(height: 24),
        Text(
          'Old files (90+ days)',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        _FileList(
          items: result.oldFiles,
          empty: 'No old files',
          subtitle: (item) => Fmt.bytes(item.fileSize),
        ),
        const SizedBox(height: 24),
        Text(
          'Empty folders',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        if (result.emptyFolders.isEmpty)
          Text('No empty folders', style: theme.textTheme.bodySmall)
        else
          for (final path in result.emptyFolders)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.folder_off_outlined),
              title: Text(path, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.result, required this.color});
  final StorageScanResult result;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaBytes = result.mediaBytes;
    final otherBytes = result.thumbnailBytes + result.cacheBytes;
    final total = mediaBytes + otherBytes;
    final fraction = total == 0 ? 0.0 : mediaBytes / total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Library usage',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${result.fileCount} files',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${Fmt.bytes(mediaBytes)} media · ${Fmt.bytes(otherBytes)} cache',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: fraction,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            color: color,
          ),
        ],
      ),
    );
  }
}

class _BreakdownTile extends StatelessWidget {
  const _BreakdownTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(label),
      trailing: Text(value, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

class _FileList extends StatelessWidget {
  const _FileList({
    required this.items,
    required this.empty,
    required this.subtitle,
  });

  final List<MediaItem> items;
  final String empty;
  final String Function(MediaItem item) subtitle;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text(empty, style: Theme.of(context).textTheme.bodySmall);
    }
    return Column(
      children: [
        for (final item in items)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: ArtworkWidget(
              title: item.title ?? item.fileName,
              path: item.thumbnailPath ?? item.albumArtPath,
              size: 40,
              isVideo: item.mediaType == HikmahMediaType.video.value,
            ),
            title: Text(
              item.title ?? item.fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(subtitle(item)),
          ),
      ],
    );
  }
}