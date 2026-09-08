import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/duration_extensions.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/file_size_formatter.dart';
import '../../../core/storage/repositories/media_repository.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/library_provider.dart' show MediaItemDisplay;
import '../../providers/player_provider.dart';
import '../../providers/scanner_provider.dart';
import '../../providers/storage_provider.dart';
import 'collection_screen.dart';
import 'folders/folder_explorer_screen.dart';
import 'playlists/playlists_tab.dart';

/// The Home dashboard — landing tab of the app.
///
/// Shows the device library through a set of live, derived sections:
/// quick actions, continue watching, recently added, favorites, most played
/// and smart collections. All sections stream from the shared
/// [homeDashboardDataProvider], so they update as the library changes.
class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(homeDashboardDataProvider);

    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _DashboardHeader(
              onRescan: () => _refreshLibrary(context, ref),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primaryCyan,
                backgroundColor: AppColors.navySurface,
                onRefresh: () => _refreshLibrary(context, ref),
                child: dashboardAsync.when(
                  data: (data) => _DashboardBody(data: data),
                  loading: () => const _DashboardLoading(),
                  error: (e, _) => _DashboardError(
                    message: 'Error loading dashboard: $e',
                    onRetry: () => ref.invalidate(homeDashboardDataProvider),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshLibrary(BuildContext context, WidgetRef ref) async {
    await ref.read(scannerProvider.notifier).startScan();
    ref.invalidate(homeDashboardDataProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Library scan complete')),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Header: greeting, storage ring, rescan & search.
// ═══════════════════════════════════════════════════════════════════

class _DashboardHeader extends ConsumerWidget {
  const _DashboardHeader({required this.onRescan});

  final VoidCallback onRescan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final storage = ref.watch(storageInfoProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.deepNavy,
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
            width: 0.5,
          ),
        ),
      ),
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
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primaryCyan, AppColors.primaryPurple],
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
                    'بارك الله فيك',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  if (storage != null)
                    Text(
                      '${storage.usedGB.toStringAsFixed(1)} / ${storage.totalGB.toStringAsFixed(1)} GB used',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
            if (storage != null)
              Padding(
                padding: const EdgeInsets.only(right: AppDimensions.xs),
                child: _StorageRing(percent: storage.usedPercent),
              ),
            IconButton(
              tooltip: 'Refresh Library',
              icon: const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: 22,
              ),
              onPressed: onRescan,
            ),
            IconButton(
              tooltip: 'Search',
              icon: const Icon(
                Icons.search_rounded,
                color: Colors.white,
                size: 22,
              ),
              onPressed: () => context.push(RouteNames.search),
            ),
          ],
        ),
      ),
    );
  }
}

class _StorageRing extends StatelessWidget {
  const _StorageRing({required this.percent});

  final double percent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              value: percent,
              strokeWidth: 3,
              valueColor: const AlwaysStoppedAnimation(AppColors.primaryCyan),
              backgroundColor: Colors.white12,
            ),
          ),
          Text(
            '${(percent * 100).round()}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Body.
// ═══════════════════════════════════════════════════════════════════

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.data});

  final DashboardData data;

  bool get _isEmpty =>
      data.continueWatching.isEmpty &&
      data.recentlyAdded.isEmpty &&
      data.favorites.isEmpty &&
      data.mostPlayed.isEmpty;

  @override
  Widget build(BuildContext context) {
    final hasCollections = data.shortVideos.isNotEmpty ||
        data.cinema.isNotEmpty ||
        data.losslessAudio.isNotEmpty;

    if (_isEmpty && !hasCollections) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.md),
        children: const [
          _QuickActionsSection(),
          SizedBox(height: AppDimensions.xxl),
          _DashboardEmpty(),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.md),
      children: [
        const _QuickActionsSection(),
        const SizedBox(height: AppDimensions.lg),

        if (data.continueWatching.isNotEmpty) ...[
          _SectionHeader(
            title: 'Continue Watching',
            icon: Icons.play_circle_fill,
            iconColor: AppColors.primaryCyan,
            onSeeAll: () => context.push(RouteNames.history),
          ),
          _MediaHorizontalList(items: data.continueWatching, showProgress: true),
          const SizedBox(height: AppDimensions.lg),
        ],

        if (data.recentlyAdded.isNotEmpty) ...[
          _SectionHeader(
            title: 'Recently Added',
            icon: Icons.new_releases_rounded,
            iconColor: AppColors.primaryPurple,
            onSeeAll: () => context.go(RouteNames.video),
          ),
          _MediaHorizontalList(items: data.recentlyAdded, showDate: true),
          const SizedBox(height: AppDimensions.lg),
        ],

        if (data.favorites.isNotEmpty) ...[
          _SectionHeader(
            title: 'Favorites',
            icon: Icons.favorite_rounded,
            iconColor: const Color(0xFFE5484D),
            onSeeAll: () => context.push(RouteNames.favorites),
          ),
          _MediaHorizontalList(items: data.favorites),
          const SizedBox(height: AppDimensions.lg),
        ],

        if (data.mostPlayed.isNotEmpty) ...[
          _SectionHeader(
            title: 'Most Played',
            icon: Icons.local_fire_department_rounded,
            iconColor: const Color(0xFFFFA500),
          ),
          _MediaHorizontalList(
            items: data.mostPlayed,
            showBadge: (item) => '${item.playCount}x',
          ),
          const SizedBox(height: AppDimensions.lg),
        ],

        if (hasCollections) ...[
          _SectionHeader(
            title: 'Smart Collections',
            icon: Icons.auto_awesome_rounded,
            iconColor: AppColors.primaryPink,
          ),
          _SmartCollectionsSection(data: data),
          const SizedBox(height: AppDimensions.xxl),
        ] else
          const SizedBox(height: AppDimensions.lg),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Quick actions.
// ═══════════════════════════════════════════════════════════════════

class _QuickAction {
  const _QuickAction(this.label, this.icon, this.color, this.onTap);

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection();

  void _openPlaylistLibrary(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const PlaylistLibraryScreen(),
      ),
    );
  }

  void _openFolderExplorer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const FolderExplorerScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction('Videos', Icons.movie_rounded, AppColors.primaryCyan,
          () => context.go(RouteNames.video)),
      _QuickAction('Music', Icons.music_note_rounded, AppColors.primaryPurple,
          () => context.go(RouteNames.music)),
      _QuickAction('Playlists', Icons.playlist_play_rounded,
          AppColors.primaryPink, () => _openPlaylistLibrary(context)),
      _QuickAction('Folders', Icons.folder_copy_rounded, const Color(0xFFFFA500),
          () => _openFolderExplorer(context)),
      _QuickAction('Favorites', Icons.favorite_rounded, const Color(0xFFE5484D),
          () => context.push(RouteNames.favorites)),
      _QuickAction('Downloads', Icons.download_for_offline_rounded,
          const Color(0xFF34C759), () => context.push(RouteNames.settingsStorage)),
    ];

    return SizedBox(
      height: 96,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final action = actions[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: action.onTap,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 76,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.navySurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: action.color.withValues(alpha: 0.3),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: action.color.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(action.icon, color: action.color, size: 22),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      action.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Section header & horizontal media carousels.
// ═══════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    this.iconColor,
    this.onSeeAll,
  });

  final String title;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.md,
        vertical: AppDimensions.xs,
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor ?? AppColors.primaryCyan, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          if (onSeeAll != null)
            InkWell(
              onTap: onSeeAll,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: const Row(
                  children: [
                    Text(
                      'See All',
                      style: TextStyle(
                        color: AppColors.primaryCyan,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.primaryCyan,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MediaHorizontalList extends ConsumerWidget {
  const _MediaHorizontalList({
    required this.items,
    this.showProgress = false,
    this.showDate = false,
    this.showBadge,
  });

  final List<MediaItem> items;
  final bool showProgress;
  final bool showDate;
  final String Function(MediaItem item)? showBadge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 170,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _MediaCard(
            item: item,
            showProgress: showProgress,
            showDate: showDate,
            badge: showBadge?.call(item),
            onTap: () {
              ref
                  .read(playerControllerProvider.notifier)
                  .playMedia(item);
            },
          );
        },
      ),
    );
  }
}

class _MediaCard extends StatelessWidget {
  const _MediaCard({
    required this.item,
    required this.onTap,
    this.showProgress = false,
    this.showDate = false,
    this.badge,
  });

  final MediaItem item;
  final VoidCallback onTap;
  final bool showProgress;
  final bool showDate;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final subtitle = item.isVideo
        ? FileSizeFormatter.format(item.fileSize)
        : (item.artist != null && item.artist!.isNotEmpty
            ? item.artist!
            : 'Audio Track');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.navySurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: AppColors.navySurfaceVariant,
                    child: Icon(
                      item.isVideo
                          ? Icons.video_collection_rounded
                          : Icons.audiotrack_rounded,
                      color: Colors.white30,
                      size: 36,
                    ),
                  ),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  if (badge != null)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPink,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (showDate)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          item.dateAdded > 0
                              ? _dayLabel(
                                  DateTime.fromMillisecondsSinceEpoch(
                                    item.dateAdded,
                                  ),
                                )
                              : 'Recently',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.duration.formatted,
                        style: const TextStyle(color: Colors.white, fontSize: 9),
                      ),
                    ),
                  ),
                  if (showProgress && item.hasResumePosition)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: LinearProgressIndicator(
                        value: item.progressPercent,
                        minHeight: 3,
                        backgroundColor: Colors.white12,
                        valueColor: AlwaysStoppedAnimation(item.isVideo
                            ? AppColors.primaryCyan
                            : AppColors.primaryPink),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.displayTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _dayLabel(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(time.year, time.month, time.day);
    final diff = today.difference(day).inDays;
    if (diff <= 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${_months[time.month - 1]} ${time.day}';
  }

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
}

// ═══════════════════════════════════════════════════════════════════
//  Smart collections.
// ═══════════════════════════════════════════════════════════════════

class _SmartCollection {
  const _SmartCollection(this.title, this.subtitle, this.icon, this.gradient);

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
}

class _SmartCollectionsSection extends StatelessWidget {
  const _SmartCollectionsSection({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final collections = [
      _SmartCollection(
        'Short Videos',
        '${data.shortVideos.length} clips · < 5 min',
        Icons.timer_rounded,
        const [Color(0xFF3B9EFF), Color(0xFF1A237E)],
      ),
      _SmartCollection(
        '4K Cinema',
        '${data.cinema.length} films · ≥ 100 min',
        Icons.movie_creation_rounded,
        const [Color(0xFF7B3FE4), Color(0xFF311B92)],
      ),
      _SmartCollection(
        'Lossless Audio',
        '${data.losslessAudio.length} tracks · FLAC / hi-res',
        Icons.graphic_eq_rounded,
        const [Color(0xFFE535AB), Color(0xFF4A148C)],
      ),
    ].where((c) => _countFor(c.title) > 0).toList();

    if (collections.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
      child: Column(
        children: [
          for (final collection in collections)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CollectionCard(
                title: collection.title,
                subtitle: collection.subtitle,
                icon: collection.icon,
                gradient: collection.gradient,
                onTap: () => _open(context, collection.title),
              ),
            ),
        ],
      ),
    );
  }

  int _countFor(String title) => switch (title) {
        'Short Videos' => data.shortVideos.length,
        '4K Cinema' => data.cinema.length,
        _ => data.losslessAudio.length,
      };

  void _open(BuildContext context, String title) {
    final items = switch (title) {
      'Short Videos' => data.shortVideos,
      '4K Cinema' => data.cinema,
      _ => data.losslessAudio,
    };
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            CollectionScreen(title: title, items: items),
      ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  const _CollectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Loading & empty states.
// ═══════════════════════════════════════════════════════════════════

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppDimensions.md),
      children: [
        Container(
          height: 90,
          decoration: BoxDecoration(
            color: AppColors.navySurface,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: AppColors.navySurface,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: AppColors.navySurface,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ],
    );
  }
}

class _DashboardEmpty extends StatelessWidget {
  const _DashboardEmpty();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl),
      child: Column(
        children: [
          const Icon(
            Icons.video_library_outlined,
            size: 64,
            color: Colors.white24,
          ),
          const SizedBox(height: 16),
          const Text(
            'No media found yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pull down or tap refresh to scan your device storage '
            '(SD card, USB-OTG and music included).',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white70, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}