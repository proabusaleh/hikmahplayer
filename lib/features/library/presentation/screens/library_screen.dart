import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../core/services/library_service.dart';
import '../../../player/domain/models/media_item.dart';
import '../../domain/models/collection.dart';
import '../../domain/models/library_item.dart';
import '../../domain/models/library_query.dart';
import '../widgets/filter_drawer.dart';
import '../widgets/media_grid.dart';
import '../widgets/storage_stats_card.dart';
import 'collection_screen.dart';
import 'media_detail_screen.dart';

/// Main library screen: scan roots, storage analysis, collections and the
/// searchable media grid (section 3.1).
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  LibraryService? _library;
  LibraryQuery _query = const LibraryQuery();
  String _search = '';

  LibraryService get _lib => _library!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_library == null) {
      _library = AppScope.of(context).library;
      _library!.addListener(_onLibraryChanged);
    }
  }

  void _onLibraryChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _library?.removeListener(_onLibraryChanged);
    super.dispose();
  }

  List<LibraryItem> get _results => _lib.query(_query.copyWith(text: _search));

  List<LibraryItem> get _recent => _lib.query(const LibraryQuery(
        sortBy: SortField.dateAdded,
        sortOrder: SortOrder.descending,
      )).take(12).toList();

  @override
  Widget build(BuildContext context) {
    final lib = _lib;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            tooltip: 'Scan folders',
            icon: const Icon(Icons.refresh),
            onPressed: () => _scanAll(),
          ),
          IconButton(
            tooltip: 'Sort & filter',
            icon: const Icon(Icons.tune),
            onPressed: () => _openFilters(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search library',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _search = ''),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
        ),
      ),
      body: lib.folders.isEmpty
          ? _EmptyLibrary(onAddFolder: () => _addFolder())
          : RefreshIndicator(
              onRefresh: () async {
                await _scanAll();
              },
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  if (lib.isScanning.value) const _ScanBanner(),
                  if (lib.computeStorageStats().totalFiles > 0)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: StorageStatsCard(stats: lib.computeStorageStats()),
                    ),
                  if (lib.collections.isNotEmpty) ...[
                    _SectionHeader(
                      title: 'Collections',
                      onMore: () => _openCollections(),
                    ),
                    _buildCollections(lib.collections),
                  ],
                  if (_recent.isNotEmpty) ...[
                    const _SectionHeader(title: 'Recently added'),
                    _buildRecent(),
                  ],
                  _SectionHeader(
                    title: 'All media',
                    trailing: '${_results.length} items',
                  ),
                  if (_results.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          _search.isEmpty
                              ? 'No media yet. Scan a folder to get started.'
                              : 'Nothing matches "$_search".',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    )
                  else
                    MediaGrid(
                      items: _results,
                      onTap: (item) => _openItem(item),
                    ),
                ],
              ),
            ),
      floatingActionButton: lib.folders.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _addFolder(),
              icon: const Icon(Icons.create_new_folder_outlined),
              label: const Text('Add folder'),
            )
          : null,
    );
  }

  Widget _buildCollections(List<LibraryCollection> collections) {
    final sorted = [...collections]..sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return a.sortOrder.compareTo(b.sortOrder);
      });
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: sorted.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final collection = sorted[index];
          final count = _lib.itemsInCollection(collection.id).length;
          return ActionChip(
            avatar: Icon(
              collection.isPinned ? Icons.push_pin : Icons.collections_bookmark,
              size: 18,
            ),
            label: Text('${collection.name} ($count)'),
            onPressed: () => _openCollection(collection),
          );
        },
      ),
    );
  }

  Widget _buildRecent() {
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _recent.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = _recent[index];
          return InkWell(
            onTap: () => _openItem(item),
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 92,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      width: 92,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: item.media.artworkUri == null
                          ? Icon(
                              item.media.type == MediaType.audio
                                  ? Icons.music_note
                                  : Icons.movie,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item.media.artworkUri!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const SizedBox.shrink(),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.media.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _scanAll() async {
    final results = await _lib.scanAll();
    if (!mounted) return;
    final added = results.fold<int>(0, (sum, r) => sum + r.added);
    final updated = results.fold<int>(0, (sum, r) => sum + r.updated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Scan finished: $added added, $updated updated')),
    );
  }

  Future<void> _openFilters() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => FilterDrawer(initial: _query, onChanged: (q) {
        setState(() => _query = q);
      }),
    );
  }

  Future<void> _addFolder() async {
    final path = await showDialog<String>(
      context: context,
      builder: (context) => const _AddFolderDialog(),
    );
    if (path == null || path.trim().isEmpty || !mounted) return;
    try {
      final folder = _lib.addFolder(path.trim());
      final result = await _lib.scanFolder(folder.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${folder.displayName}: ${result.added} added, '
            '${result.updated} updated, ${result.removed} removed')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not scan folder: $error')),
      );
    }
  }

  void _openItem(LibraryItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MediaDetailScreen(itemId: item.id),
      ),
    );
  }

  void _openCollection(LibraryCollection collection) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CollectionScreen(collectionId: collection.id),
      ),
    );
  }

  void _openCollections() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (context, controller) => _AllCollectionsSheet(
          library: _lib,
          scrollController: controller,
          onOpen: (collection) {
            Navigator.pop(context);
            _openCollection(collection);
          },
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing, this.onMore});

  final String title;
  final String? trailing;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          if (trailing != null)
            Text(
              trailing!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          if (onMore != null)
            TextButton(onPressed: onMore, child: const Text('All')),
        ],
      ),
    );
  }
}

class _ScanBanner extends StatelessWidget {
  const _ScanBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text('Scanning folders…',
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary({required this.onAddFolder});

  final VoidCallback onAddFolder;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.video_library_outlined,
              size: 72, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text('Your library is empty',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Add a folder to index your local media.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAddFolder,
            icon: const Icon(Icons.create_new_folder_outlined),
            label: const Text('Add folder'),
          ),
        ],
      ),
    );
  }
}

class _AddFolderDialog extends StatefulWidget {
  const _AddFolderDialog();

  @override
  State<_AddFolderDialog> createState() => _AddFolderDialogState();
}

class _AddFolderDialogState extends State<_AddFolderDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add media folder'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: r'C:\Users\you\Videos',
          labelText: 'Absolute folder path',
        ),
        onSubmitted: (_) => Navigator.pop(context, _controller.text),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Scan'),
        ),
      ],
    );
  }
}

class _AllCollectionsSheet extends StatelessWidget {
  const _AllCollectionsSheet({
    required this.library,
    required this.scrollController,
    required this.onOpen,
  });

  final LibraryService library;
  final ScrollController scrollController;
  final ValueChanged<LibraryCollection> onOpen;

  @override
  Widget build(BuildContext context) {
    final collections = library.collections;
    return ListView(
      controller: scrollController,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Collections', style: Theme.of(context).textTheme.titleLarge),
        ),
        for (final collection in collections)
          ListTile(
            leading: const Icon(Icons.collections_bookmark_outlined),
            title: Text(collection.name),
            subtitle: Text(
              '${library.itemsInCollection(collection.id).length} items'
              '${collection.description == null ? '' : ' · ${collection.description}'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: collection.isPinned
                ? const Icon(Icons.push_pin, size: 18)
                : null,
            onTap: () => onOpen(collection),
          ),
      ],
    );
  }
}
