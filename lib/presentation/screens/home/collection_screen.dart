import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/duration_extensions.dart';
import '../../../core/storage/repositories/media_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/file_size_formatter.dart';
import '../../providers/library_provider.dart' show MediaItemDisplay;
import '../../providers/player_provider.dart';

/// Renders a derived collection (smart collection, results list) with a
/// play-able list of [items].
class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({
    super.key,
    required this.title,
    required this.items,
  });

  final String title;
  final List<MediaItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      appBar: AppBar(
        backgroundColor: AppColors.deepNavy,
        foregroundColor: Colors.white,
        title: Text(title),
      ),
      body: items.isEmpty
          ? const Center(
              child: Text(
                'Nothing here yet',
                style: TextStyle(color: Colors.white54),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: AppDimensions.sm),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _CollectionTile(
                  item: item,
                  onTap: () {
                    ref
                        .read(playerControllerProvider.notifier)
                        .playQueue(items, startIndex: index);
                  },
                );
              },
            ),
    );
  }
}

class _CollectionTile extends StatelessWidget {
  const _CollectionTile({required this.item, required this.onTap});

  final MediaItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.navySurfaceVariant,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          item.isVideo ? Icons.movie_outlined : Icons.audiotrack_rounded,
          color: item.isVideo ? AppColors.primaryCyan : AppColors.primaryPink,
          size: 22,
        ),
      ),
      title: Text(
        item.displayTitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        [
          item.duration.formatted,
          if (item.isVideo) FileSizeFormatter.format(item.fileSize),
          if (!item.isVideo && item.artist != null && item.artist!.isNotEmpty)
            item.artist!,
        ].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 12,
        ),
      ),
      trailing: const Icon(
        Icons.play_circle_outline,
        color: AppColors.primaryCyan,
      ),
    );
  }
}