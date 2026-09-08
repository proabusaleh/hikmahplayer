import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/storage/repositories/folder_repository.dart';
import '../../../../core/storage/repositories/media_repository.dart';
import '../../../../core/storage/repositories/playlist_repository.dart';
import '../../../../presentation/providers/folder_explorer_provider.dart';
import '../../../../presentation/providers/library_provider.dart';
import '../../../../presentation/providers/player_provider.dart';
import '../../../../presentation/providers/search_provider.dart';
import '../../../../presentation/screens/home/folders/folder_explorer_screen.dart';
import '../../../../presentation/screens/home/playlists/playlist_detail_screen.dart';
import '../../../../presentation/screens/library/shared/library_thumbnail.dart';
import '../../../../shared/utils/format.dart';

enum SearchFilter { all, videos, music, folders, playlists }

extension _SearchFilterLabel on SearchFilter {
  String get label => switch (this) {
        SearchFilter.all => 'All',
        SearchFilter.videos => 'Videos',
        SearchFilter.music => 'Music',
        SearchFilter.folders => 'Folders',
        SearchFilter.playlists => 'Playlists',
      };
}

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  String _query = '';
  SearchFilter _filter = SearchFilter.all;
  List<String> _recentSearches = [];
  static const _recentKey = 'recent_searches';
  static const _maxRecent = 10;

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadRecent() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _recentSearches = prefs.getStringList(_recentKey) ?? [];
    });
  }

  Future<void> _saveRecent(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final recent = List<String>.from(_recentSearches);
    recent.remove(trimmed);
    recent.insert(0, trimmed);
    if (recent.length > _maxRecent) recent.removeLast();
    if (!mounted) return;
    setState(() => _recentSearches = recent);
    await prefs.setStringList(_recentKey, recent);
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      Duration(milliseconds: AppConstants.searchDebounceMs),
      () {
        if (!mounted) return;
        setState(() => _query = value);
        ref.read(searchProvider.notifier).onQueryChanged(value);
      },
    );
  }

  void _onSubmitted(String value) {
    _debounce?.cancel();
    _saveRecent(value);
    setState(() => _query = value);
    ref.read(searchProvider.notifier).onQueryChanged(value);
  }

  void _selectRecent(String value) {
    _controller.text = value;
    _focusNode.requestFocus();
    _saveRecent(value);
    setState(() => _query = value);
    ref.read(searchProvider.notifier).onQueryChanged(value);
  }

  void _clearSearch() {
    _debounce?.cancel();
    _controller.clear();
    _focusNode.requestFocus();
    setState(() => _query = '');
    ref.read(searchProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchState = ref.watch(searchProvider);
    final mediaResults = searchState.results;
    final foldersAsync = ref.watch(foldersListProvider);
    final playlists = ref.watch(playlistListProvider);

    final hasQuery = _query.trim().isNotEmpty;
    final q = _query.trim().toLowerCase();

    final filteredMedia = _filter == SearchFilter.folders ||
            _filter == SearchFilter.playlists
        ? <MediaItem>[]
        : mediaResults.where((item) {
            return switch (_filter) {
              SearchFilter.all => true,
              SearchFilter.videos => item.isVideo,
              SearchFilter.music => item.isAudio,
              _ => true,
            };
          }).toList();

    final matchedFolders =
        (_filter == SearchFilter.all || _filter == SearchFilter.folders) &&
                hasQuery
            ? (foldersAsync.valueOrNull ?? const <Folder>[]).where((f) {
                return f.name.toLowerCase().contains(q) ||
                    f.path.toLowerCase().contains(q);
              }).toList()
            : <Folder>[];

    final matchedPlaylists =
        (_filter == SearchFilter.all || _filter == SearchFilter.playlists) &&
                hasQuery
            ? playlists.where((p) {
                return p.name.toLowerCase().contains(q) ||
                    (p.description ?? '').toLowerCase().contains(q);
              }).toList()
            : <Playlist>[];

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          focusNode: _focusNode,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Search videos, music, folders\u2026',
            border: InputBorder.none,
          ),
          onChanged: _onQueryChanged,
          onSubmitted: _onSubmitted,
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearSearch,
            ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: SearchFilter.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = SearchFilter.values[index];
                return ChoiceChip(
                  label: Text(filter.label),
                  selected: _filter == filter,
                  onSelected: (_) => setState(() => _filter = filter),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: !hasQuery
                ? _buildRecent(theme)
                : _buildResults(
                    theme, filteredMedia, matchedFolders, matchedPlaylists),
          ),
        ],
      ),
    );
  }

  Widget _buildRecent(ThemeData theme) {
    if (_recentSearches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search,
                size: 72,
                color: theme.colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('Search your library', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Find videos, music, folders, and playlists.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Text(
                'RECENT SEARCHES',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove(_recentKey);
                  if (mounted) setState(() => _recentSearches = []);
                },
                child: const Text('Clear'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _recentSearches.length,
            itemBuilder: (context, index) {
              final term = _recentSearches[index];
              return ListTile(
                leading: const Icon(Icons.history, size: 20),
                title: Text(term),
                onTap: () => _selectRecent(term),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final recent = List<String>.from(_recentSearches);
                    recent.removeAt(index);
                    setState(() => _recentSearches = recent);
                    await prefs.setStringList(_recentKey, recent);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResults(
    ThemeData theme,
    List<MediaItem> media,
    List<Folder> folders,
    List<Playlist> playlists,
  ) {
    final total = media.length + folders.length + playlists.length;
    if (total == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                size: 72,
                color: theme.colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('No results found', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Try a different search term.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      children: [
        if (folders.isNotEmpty) ...[
          _SectionHeader(title: 'Folders (${folders.length})'),
          for (final folder in folders)
            ListTile(
              leading: Icon(Icons.folder_outlined,
                  color: theme.colorScheme.primary),
              title: Text(folder.name,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(folder.path,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Text('${folder.mediaCount}',
                  style: theme.textTheme.bodySmall),
              onTap: () {
                ref.read(folderExplorerPathProvider.notifier).state =
                    folder.path;
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const FolderExplorerScreen()),
                );
              },
            ),
        ],
        if (playlists.isNotEmpty) ...[
          _SectionHeader(title: 'Playlists (${playlists.length})'),
          for (final playlist in playlists)
            ListTile(
              leading: Icon(
                playlist.type == PlaylistType.video
                    ? Icons.video_library_rounded
                    : Icons.library_music_rounded,
                color: theme.colorScheme.primary,
              ),
              title: Text(playlist.name,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text('${playlist.itemCount} items',
                  style: theme.textTheme.bodySmall),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        PlaylistDetailScreen.playlist(playlist),
                  ),
                );
              },
            ),
        ],
        if (media.isNotEmpty) ...[
          _SectionHeader(title: 'Media (${media.length})'),
          for (final item in media)
            ListTile(
              leading: LibraryThumbnail(
                path: item.thumbnailPath ?? item.albumArtPath,
                placeholderIcon: item.isVideo
                    ? Icons.movie_rounded
                    : Icons.music_note_rounded,
              ),
              title: Text(item.displayTitle,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                '${item.isVideo ? 'Video' : 'Music'}'
                '${item.artist != null ? ' \u00b7 ${item.artist}' : ''}'
                ' \u00b7 ${Fmt.duration(item.duration)}',
                style: theme.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                ref.read(playerControllerProvider.notifier).playQueue(
                      media,
                      startIndex: media.indexOf(item),
                    );
              },
            ),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
