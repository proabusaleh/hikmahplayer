import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/route_names.dart';
import '../../core/theme/app_dimensions.dart';
import '../../features/player/presentation/screens/mini_player.dart';
import '../../presentation/providers/player_provider.dart';

/// The redesigned app shell: a mini player pinned above a custom 3-tab
/// bottom navigation (VIDEO / MUSIC / ME).
class HomeShell extends ConsumerWidget {
  final Widget child;

  const HomeShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerControllerProvider);
    final showMiniPlayer = playerState.hasMedia;
    final currentIndex = _getCurrentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showMiniPlayer) const MiniPlayer(),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.xl,
                  vertical: AppDimensions.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavTab(
                      icon: Icons.movie_outlined,
                      activeIcon: Icons.movie,
                      label: 'VIDEO',
                      isActive: currentIndex == 0,
                      onTap: () => context.go(RouteNames.video),
                    ),
                    _NavTab(
                      icon: Icons.music_note_outlined,
                      activeIcon: Icons.music_note,
                      label: 'MUSIC',
                      isActive: currentIndex == 1,
                      onTap: () => context.go(RouteNames.music),
                    ),
                    _NavTab(
                      icon: Icons.person_outline,
                      activeIcon: Icons.person,
                      label: 'ME',
                      isActive: currentIndex == 2,
                      onTap: () => context.go(RouteNames.me),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _getCurrentIndex(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    if (path.startsWith(RouteNames.music)) return 1;
    if (path.startsWith(RouteNames.me)) return 2;
    return 0; // Video is default.
  }
}

/// Animated tab entry of the bottom navigation.
class _NavTab extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.primary;
    final inactiveColor = theme.colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 26,
              color: isActive ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isActive ? activeColor : inactiveColor,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}