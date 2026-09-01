import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/route_names.dart';
import '../../core/theme/app_dimensions.dart';
import '../providers/storage_provider.dart';

/// Shared Hikmah brand top bar: logo + Arabic greeting, a storage usage ring,
/// a search shortcut and optional extra actions.
class HikmahAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String? title;
  final bool showStorage;
  final bool showSearch;
  final List<Widget>? actions;

  const HikmahAppBar({
    super.key,
    this.title,
    this.showStorage = true,
    this.showSearch = true,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final storageInfo = ref.watch(storageInfoProvider);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.md,
            vertical: AppDimensions.sm,
          ),
          child: Row(
            children: [
              // ─── Logo ───
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.mosque,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title ?? 'بارك الله فيك',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (showStorage && storageInfo != null)
                      Text(
                        '${storageInfo.usedGB.toStringAsFixed(1)} / '
                        '${storageInfo.totalGB.toStringAsFixed(1)} GB used',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),

              // ─── Storage Indicator ───
              if (showStorage && storageInfo != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _StorageIndicator(
                    usedPercent: storageInfo.usedPercent,
                  ),
                ),

              // ─── Search ───
              if (showSearch)
                IconButton(
                  icon: Icon(
                    Icons.search,
                    color: theme.colorScheme.onSurface,
                    size: 24,
                  ),
                  onPressed: () => context.push(RouteNames.search),
                ),

              // ─── Extra actions ───
              if (actions != null) ...actions!,
            ],
          ),
        ),
      ),
    );
  }
}

/// Circular progress ring with a storage glyph in the centre.
class _StorageIndicator extends StatelessWidget {
  final double usedPercent;

  const _StorageIndicator({required this.usedPercent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = usedPercent > 0.9
        ? Colors.red
        : usedPercent > 0.7
            ? Colors.orange
            : theme.colorScheme.primary;

    return SizedBox(
      width: 32,
      height: 32,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: usedPercent,
            strokeWidth: 3,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(color),
          ),
          Icon(
            Icons.storage_outlined,
            size: 14,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}