import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/route_names.dart';
import '../../core/theme/app_dimensions.dart';
import '../providers/storage_provider.dart';

class HikmahAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String? title;
  final bool showStorage;
  final bool showSearch;
  final bool showActions;
  final List<Widget>? actions;

  const HikmahAppBar({
    super.key,
    this.title,
    this.showStorage = true,
    this.showSearch = true,
    this.showActions = true,
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
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.15),
            width: 0.5,
          ),
        ),
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
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.75),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title ?? 'Hikmah Player',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (showStorage && storageInfo != null)
                      Text(
                        '${storageInfo.usedGB.toStringAsFixed(1)} / ${storageInfo.totalGB.toStringAsFixed(1)} GB',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),

              if (showActions) ...[
                if (showSearch)
                  IconButton(
                    icon: Icon(
                      Icons.search_rounded,
                      color: theme.colorScheme.onSurface,
                      size: 22,
                    ),
                    onPressed: () => context.push(RouteNames.search),
                  ),
                if (actions != null) ...actions!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
