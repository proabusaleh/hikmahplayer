import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/storage/repositories/folder_repository.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_dimensions.dart';
import '../../../../screens/library/shared/library_thumbnail.dart';
import 'folder_actions_sheet.dart';

/// Card showing an indexed folder with its stats and flags.
class FolderCardTile extends ConsumerWidget {
  const FolderCardTile({
    super.key,
    required this.folder,
    required this.onTap,
  });

  final Folder folder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(AppDimensions.md),
        leading: SizedBox(
          width: 52,
          height: 52,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LibraryThumbnail(
              path: folder.thumbnailPath,
              placeholderIcon: Icons.folder_rounded,
              backgroundColor: AppColors.primaryPink.withValues(alpha: 0.14),
              foregroundColor: AppColors.primaryPink,
            ),
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                folder.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ..._badges(theme),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            _FolderStatsLine(folder: folder),
            const SizedBox(height: 2),
            Text(
              _shortPath(folder.path),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert_rounded, size: 20),
          onPressed: () => showFolderActionsSheet(context, ref, folder),
          tooltip: 'Folder actions',
        ),
      ),
    );
  }

  List<Widget> _badges(ThemeData theme) {
    final badges = <Widget>[];
    void add(String label, Color color) {
      badges.add(Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ));
    }

    if (folder.isPinned) add('PIN', AppColors.primaryCyan);
    if (folder.isProtected) add('PROTECTED', AppColors.primaryPurple);
    if (folder.isHidden) add('HIDDEN', theme.colorScheme.tertiary);
    if (folder.isExcluded) add('EXCLUDED', theme.colorScheme.error);
    return badges;
  }

  static String _shortPath(String path) {
    final length = path.length;
    if (length <= 40) return path;
    return '…${path.substring(length - 39)}';
  }
}

class _FolderStatsLine extends StatelessWidget {
  const _FolderStatsLine({required this.folder});

  final Folder folder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = <String>[
      if (folder.videoCount > 0)
        '${folder.videoCount} video${folder.videoCount == 1 ? '' : 's'}',
      if (folder.musicCount > 0)
        '${folder.musicCount} song${folder.musicCount == 1 ? '' : 's'}',
      if (folder.mediaCount > 0) '${folder.mediaCount} items',
      if (folder.totalSizeBytes > 0) folder.displaySize,
    ];
    final label = items.isEmpty ? 'Empty · tap to manage' : items.join('  •  ');

    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}