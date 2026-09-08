import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/repositories/media_repository.dart';
import '../../../providers/folder_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/services_provider.dart';
import '../../home/video/widgets/folder_detail_screen.dart';
import '../shared/empty_states.dart';
import '../shared/library_selection.dart';
import '../shared/library_sort.dart';
import '../shared/library_sort_sheet.dart';
import 'video_action_bottom_sheet.dart';
import 'video_filter_sheet.dart';
import 'video_library_provider.dart';
import 'video_list_renderer.dart';
import 'video_selection_app_bar.dart';

/// Full-screen videos library with tabs (All Videos / Folders), search,
/// filter, sort, and multi-select.
class VideoLibraryScreen extends ConsumerStatefulWidget {
  const VideoLibraryScreen({super.key, this.embedded = false});

  /// When true, hides the AppBar so parent widgets can embed the content.
  final bool embedded;

  @override
  ConsumerState<VideoLibraryScreen> createState() => _VideoLibraryScreenState();
}

class _VideoLibraryScreenState extends ConsumerState<VideoLibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  bool _searchOpen = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _searchOpen = !_searchOpen;
      if (!_searchOpen) {
        _searchController.clear();
        ref.read(videoSearchQueryProvider.notifier).state = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(videoLibraryProvider);
    final videos = ref.watch(videosLibraryListProvider);
    final selection = ref.watch(videoSelectionProvider);
    final filterCount = ref.watch(videoFilterCountProvider);

    final body = selection.isActive
        ? _buildVideoList(state, videos, selection)
        : TabBarView(
            controller: _tabController,
            children: [
              _buildVideoList(state, videos, selection),
              _buildFolderGrid(context, ref),
            ],
          );

    if (widget.embedded) {
      return Column(
        children: [
          _buildSearchBar(context, ref, videos, filterCount),
          _buildTabBar(context),
          Expanded(child: body),
        ],
      );
    }

    return Scaffold(
      appBar: selection.isActive
          ? VideoSelectionAppBar(
              count: selection.count,
              total: videos.length,
              onSelectAll: () => selection.selectAll(videos.map((v) => v.id)),
              onClear: selection.clear,
              onPlay: () {
                final selectedIds = selection.selected;
                final first = videos.indexWhere(
                  (v) => v.id == (selectedIds.isEmpty ? '' : selectedIds.first),
                );
                if (first >= 0) {
                  ref
                      .read(playerControllerProvider.notifier)
                      .playQueue(videos, startIndex: first);
                }
              },
              onFavorite: () async {
                final services = ref.read(appServicesProvider);
                final ids = selection.selected
                    .map((id) => videos.firstWhere((v) => v.id == id))
                    .toList();
                final allFavorite = ids.every((v) => v.isFavorite);
                for (final v in ids) {
                  await services.media.setFavorite(v.id, !allFavorite);
                }
                selection.clear();
              },
              onDelete: () => _deleteSelected(context, ref, selection, videos),
            )
          : AppBar(
              title: _searchOpen
                  ? TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Search videos...',
                        border: InputBorder.none,
                      ),
                      onChanged: (q) =>
                          ref.read(videoSearchQueryProvider.notifier).state = q,
                    )
                  : const Text('Videos'),
              actions: [
                if (_searchOpen)
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close search',
                    onPressed: _toggleSearch,
                  )
                else ...[
                  IconButton(
                    icon: const Icon(Icons.search_rounded),
                    tooltip: 'Search videos',
                    onPressed: _toggleSearch,
                  ),
                  IconButton(
                    icon: const Icon(Icons.playlist_play_rounded),
                    tooltip: 'Play all',
                    onPressed: videos.isEmpty
                        ? null
                        : () => ref
                              .read(playerControllerProvider.notifier)
                              .playQueue(videos),
                  ),
                  IconButton(
                    icon: Icon(_viewIcon(state.viewMode)),
                    tooltip: 'Switch view',
                    onPressed: () => _cycleViewMode(ref),
                  ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.sort_rounded),
                        tooltip: 'Sort library',
                        onPressed: () async {
                          final result = await showLibrarySortSheet(
                            context,
                            current: state.sort,
                            fields: const [
                              LibrarySortField.name,
                              LibrarySortField.dateAdded,
                              LibrarySortField.dateModified,
                              LibrarySortField.size,
                              LibrarySortField.duration,
                              LibrarySortField.resolution,
                              LibrarySortField.lastPlayed,
                              LibrarySortField.playCount,
                            ],
                          );
                          if (result != null) {
                            ref
                                .read(videoLibraryProvider.notifier)
                                .setSort(result);
                          }
                        },
                      ),
                    ],
                  ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.tune_rounded),
                        tooltip: 'Filter',
                        onPressed: () =>
                            showVideoFilterSheet(context, ref: ref),
                      ),
                      if (filterCount > 0)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$filterCount',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
              bottom: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'All Videos'),
                  Tab(text: 'Folders'),
                ],
              ),
            ),
      body: body,
    );
  }

  Widget _buildSearchBar(
    BuildContext context,
    WidgetRef ref,
    List<MediaItem> videos,
    int filterCount,
  ) {
    if (_searchOpen) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search videos...',
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
                onChanged: (q) =>
                    ref.read(videoSearchQueryProvider.notifier).state = q,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Close search',
              onPressed: _toggleSearch,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: _toggleSearch,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Search videos',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.tune_rounded),
                tooltip: 'Filter',
                onPressed: () => showVideoFilterSheet(context, ref: ref),
              ),
              if (filterCount > 0)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$filterCount',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort library',
            onPressed: () async {
              final result = await showLibrarySortSheet(
                context,
                current: ref.read(videoLibraryProvider).sort,
                fields: const [
                  LibrarySortField.name,
                  LibrarySortField.dateAdded,
                  LibrarySortField.dateModified,
                  LibrarySortField.size,
                  LibrarySortField.duration,
                  LibrarySortField.resolution,
                  LibrarySortField.lastPlayed,
                  LibrarySortField.playCount,
                ],
              );
              if (result != null) {
                ref.read(videoLibraryProvider.notifier).setSort(result);
              }
            },
          ),
          IconButton(
            icon: Icon(_viewIcon(ref.read(videoLibraryProvider).viewMode)),
            tooltip: 'Switch view',
            onPressed: () => _cycleViewMode(ref),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surface,
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'All Videos'),
          Tab(text: 'Folders'),
        ],
      ),
    );
  }

  Widget _buildVideoList(
    VideoLibraryState state,
    List<MediaItem> videos,
    LibrarySelectionController selection,
  ) {
    if (videos.isEmpty) {
      return const LibraryEmptyState(
        icon: Icons.video_library_outlined,
        title: 'No videos found',
        message: 'Try adjusting your search or filters.',
      );
    }
    return VideoListRenderer(
      videos: videos,
      viewMode: state.viewMode,
      selectedIds: selection.selected.toSet(),
      onPlayAt: (index) => ref
          .read(playerControllerProvider.notifier)
          .playQueue(videos, startIndex: index),
      onToggleSelection: (video) => selection.toggle(video.id),
      onLongPress: (video) => selection.begin(video.id),
      onOpenActions: (video) {
        final index = videos.indexOf(video);
        showVideoActionSheet(
          context,
          video: video,
          queue: videos,
          index: index < 0 ? 0 : index,
        );
      },
    );
  }

  Widget _buildFolderGrid(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(folderListProvider);

    return foldersAsync.when(
      data: (folders) {
        final videoFolders =
            folders.where((f) => f.mediaCount > 0).toList();
        if (videoFolders.isEmpty) {
          return const LibraryEmptyState(
            icon: Icons.folder_off_outlined,
            title: 'No video folders',
            message: 'Folders with videos will appear here.',
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.78,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: videoFolders.length,
          itemBuilder: (context, index) {
            final folder = videoFolders[index];
            return _FolderCard(
              folder: folder,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FolderDetailScreen(
                      folderPath: folder.path,
                      folderName: folder.name,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  static IconData _viewIcon(VideoLibraryViewMode mode) => switch (mode) {
        VideoLibraryViewMode.list => Icons.view_agenda_rounded,
        VideoLibraryViewMode.grid => Icons.grid_view_rounded,
        VideoLibraryViewMode.large => Icons.view_day_rounded,
        VideoLibraryViewMode.gridComfortable => Icons.dashboard_rounded,
        VideoLibraryViewMode.compact => Icons.view_list_rounded,
      };

  static void _cycleViewMode(WidgetRef ref) {
    final modes = VideoLibraryViewMode.values;
    final current = ref.read(videoLibraryProvider).viewMode;
    final nextIndex = (modes.indexOf(current) + 1) % modes.length;
    ref.read(videoLibraryProvider.notifier).setViewMode(modes[nextIndex]);
  }

  static Future<void> _deleteSelected(
    BuildContext context,
    WidgetRef ref,
    LibrarySelectionController selection,
    List<MediaItem> videos,
  ) async {
    final count = selection.count;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $count item${count == 1 ? '' : 's'}?'),
        content: const Text(
          'This removes the entries from your library. Files may remain on storage.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(appServicesProvider)
        .media
        .removeByIds(selection.selected);
    selection.clear();
  }
}

class _FolderCard extends StatelessWidget {
  const _FolderCard({required this.folder, required this.onTap});

  final dynamic folder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = folder.name as String;
    final count = folder.mediaCount as int;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.folder_rounded,
                size: 28,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              '$count video${count == 1 ? '' : 's'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
