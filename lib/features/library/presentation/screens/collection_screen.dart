import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../core/services/library_service.dart';
import '../../../player/domain/models/media_item.dart';
import '../../../player/domain/models/playback_queue.dart';
import '../../../player/presentation/screens/player_screen.dart';
import '../../domain/models/collection.dart';
import '../../domain/models/library_item.dart';
import '../widgets/media_grid.dart';

/// A single collection: its items, plus rename/pin/delete and membership
/// management (section 3.1 "multi-level collections with custom artwork").
class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key, required this.collectionId});

  final String collectionId;

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  LibraryService? _library;

  LibraryService get _lib => _library!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_library == null) {
      _library = AppScope.of(context).library;
      _library!.addListener(_onChanged);
    }
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _library?.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final collection = _lib.collections
        .where((c) => c.id == widget.collectionId)
        .firstOrNull;
    if (collection == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Collection not found.')),
      );
    }
    final items = _lib.itemsInCollection(collection.id);
    return Scaffold(
      appBar: AppBar(
        title: Text(collection.name),
        actions: [
          IconButton(
            tooltip: collection.isPinned ? 'Unpin' : 'Pin to top',
            icon: Icon(
              collection.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
            ),
            onPressed: () =>
                _lib.setCollectionPinned(collection.id, !collection.isPinned),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleAction(value, collection),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'rename',
                child: ListTile(
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Rename'),
                ),
              ),
              const PopupMenuItem(
                value: 'description',
                child: ListTile(
                  leading: Icon(Icons.notes),
                  title: Text('Edit description'),
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete_outline),
                  title: Text('Delete collection'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (collection.description != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                collection.description!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Text('${items.length} items',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                FilledButton.tonalIcon(
                  onPressed: () => _manageItems(collection.id),
                  icon: const Icon(Icons.playlist_add),
                  label: const Text('Manage'),
                ),
              ],
            ),
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'This collection is empty.\nTap Manage to add items.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            )
          else
            MediaGrid(
              items: items,
              onTap: (item) => _playFrom(items, item),
            ),
        ],
      ),
    );
  }

  Future<void> _handleAction(String action, LibraryCollection collection) async {
    switch (action) {
      case 'rename':
        final name = await _promptText(
          'Rename collection',
          'Collection name',
          initial: collection.name,
        );
        if (name == null || name.trim().isEmpty) return;
        _lib.renameCollection(collection.id, name.trim());
      case 'description':
        final description = await _promptText(
          'Edit description',
          'Description',
          initial: collection.description,
          multiline: true,
        );
        if (description == null) return;
        _lib.updateCollectionDescription(
          collection.id,
          description.trim().isEmpty ? null : description.trim(),
        );
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete collection?'),
            content: Text(
              'Items stay in your library; only "${collection.name}" is removed.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirmed == true && mounted) {
          _lib.deleteCollection(collection.id);
          Navigator.of(context).pop();
        }
    }
  }

  Future<void> _manageItems(String collectionId) async {
    final all = _lib.items;
    final memberIds = _lib.itemsInCollection(collectionId).map((i) => i.id).toSet();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (context, scrollController) => _ItemPickerSheet(
          items: all,
          memberIds: memberIds,
          library: _lib,
          collectionId: collectionId,
          scrollController: scrollController,
        ),
      ),
    );
  }

  void _playFrom(List<LibraryItem> items, LibraryItem tapped) {
    final queue = PlaybackQueue(
      items: items.map((i) => i.media).toList(),
      currentIndex: items.indexWhere((i) => i.id == tapped.id),
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PlayerScreen(queue: queue)),
    );
  }

  Future<String?> _promptText(
    String title,
    String label, {
    String? initial,
    bool multiline = false,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: initial ?? '');
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: multiline ? 4 : 1,
            decoration: InputDecoration(labelText: label),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

class _ItemPickerSheet extends StatelessWidget {
  const _ItemPickerSheet({
    required this.items,
    required this.memberIds,
    required this.library,
    required this.collectionId,
    required this.scrollController,
  });

  final List<LibraryItem> items;
  final Set<String> memberIds;
  final LibraryService library;
  final String collectionId;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final available = items.where((i) => !memberIds.contains(i.id)).toList();
    return ListView(
      controller: scrollController,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Manage items', style: Theme.of(context).textTheme.titleLarge),
              Text('${memberIds.length} in collection · ${available.length} available',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        if (available.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Every library item is already in this collection.',
                style: Theme.of(context).textTheme.bodyMedium),
          )
        else
          for (final item in available)
            ListTile(
              leading: Icon(
                item.media.type == MediaType.audio ? Icons.music_note : Icons.movie,
              ),
              title: Text(item.media.title,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                item.media.type == MediaType.audio
                    ? (item.media.artist ?? 'Audio')
                    : (item.media.year?.toString() ?? 'Video'),
              ),
              trailing: const Icon(Icons.add_circle_outline),
              onTap: () => library.addToCollection(item.id, collectionId),
            ),
      ],
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) return iterator.current;
    return null;
  }
}
