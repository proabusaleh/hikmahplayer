import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../core/services/library_service.dart';
import '../../../../shared/utils/format.dart';
import '../../../player/domain/models/media_item.dart';
import '../../../player/domain/models/playback_queue.dart';
import '../../../player/presentation/screens/player_screen.dart';
import '../../domain/models/library_item.dart';

/// Detail screen for a single library item: metadata, rating, tags,
/// collections, favourite and playback (section 3.1).
class MediaDetailScreen extends StatefulWidget {
  const MediaDetailScreen({super.key, required this.itemId});

  final String itemId;

  @override
  State<MediaDetailScreen> createState() => _MediaDetailScreenState();
}

class _MediaDetailScreenState extends State<MediaDetailScreen> {
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
    final item = _lib.itemById(widget.itemId);
    if (item == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('This item is no longer in the library.')),
      );
    }
    final media = item.media;
    return Scaffold(
      appBar: AppBar(
        title: Text(media.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: item.isFavorite ? 'Remove from favourites' : 'Add to favourites',
            icon: Icon(
              item.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: item.isFavorite ? Colors.redAccent : null,
            ),
            onPressed: () => _lib.toggleFavorite(item.id),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          _buildHeader(context, item),
          _buildMetadata(context, item),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: Text(_resumeLabel(item)),
                    onPressed: () => _play(item),
                  ),
                ),
              ],
            ),
          ),
          _buildRating(context, item),
          _buildTags(context, item),
          _buildCollections(context, item),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, LibraryItem item) {
    final theme = Theme.of(context);
    final media = item.media;
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 128,
              height: 160,
              child: media.artworkUri == null
                  ? ColoredBox(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(
                        media.type == MediaType.audio ? Icons.music_note : Icons.movie,
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  : Image.network(
                      media.artworkUri!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => ColoredBox(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(Icons.broken_image,
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(media.title, style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                if (media.type == MediaType.audio)
                  Text(
                    [media.artist, media.album].whereType<String>().join(' — '),
                    style: theme.textTheme.bodyMedium,
                  ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (media.year != null)
                      _chip(theme, '${media.year}'),
                    if (media.videoCodec != null)
                      _chip(theme, media.videoCodec!),
                    if (media.audioCodec != null)
                      _chip(theme, media.audioCodec!),
                    if (media.width != null && media.height != null)
                      _chip(theme, '${media.height}p'),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  [
                    if (media.duration != null) Fmt.duration(media.duration),
                    if (media.fileSize != null) Fmt.bytes(media.fileSize),
                    if (media.bitrate != null)
                      '${(media.bitrate! / 1000).toStringAsFixed(0)} kbps',
                    if (item.playCount > 0) 'Played ${item.playCount}x',
                  ].join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(ThemeData theme, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: theme.textTheme.labelSmall),
    );
  }

  Widget _buildMetadata(BuildContext context, LibraryItem item) {
    final theme = Theme.of(context);
    final media = item.media;
    final rows = <(String, String)>[
      if (media.genres.isNotEmpty)
        ('Genres', media.genres.join(', ')),
      if (media.uri.isNotEmpty)
        ('File', media.uri.split(RegExp(r'[\\/]')).last),
      if (media.lastPlayedAt != null)
        ('Last played', Fmt.date(media.lastPlayedAt!)),
      if (item.lastWatchedAt != null)
        ('Watched', Fmt.date(item.lastWatchedAt!)),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (final (label, value) in rows)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(label, style: theme.textTheme.labelMedium),
              subtitle: Text(value, maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
        ],
      ),
    );
  }

  Widget _buildRating(BuildContext context, LibraryItem item) {
    final theme = Theme.of(context);
    final rating = item.rating;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rating', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Row(
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    rating != null && rating / 2 >= i
                        ? Icons.star
                        : Icons.star_border,
                    color: rating != null && rating / 2 >= i
                        ? Colors.amber
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () => _lib.setRating(
                    item.id,
                    rating == (i * 2).toDouble() ? null : (i * 2).toDouble(),
                  ),
                ),
              if (rating != null)
                Text('${rating.toStringAsFixed(1)}/10',
                    style: theme.textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTags(BuildContext context, LibraryItem item) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Tags', style: theme.textTheme.titleSmall),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.add, size: 20),
                tooltip: 'Add tag',
                onPressed: () => _addTag(item),
              ),
            ],
          ),
          if (item.tags.isEmpty)
            Text('No tags yet',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ))
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final tag in item.tags)
                  InputChip(
                    label: Text(tag),
                    onDeleted: () => _lib.removeTagFromItem(item.id, tag),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCollections(BuildContext context, LibraryItem item) {
    final theme = Theme.of(context);
    final collections = _lib.collections
        .where((c) => item.collectionIds.contains(c.id))
        .toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Collections', style: theme.textTheme.titleSmall),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.add, size: 20),
                tooltip: 'Add to collection',
                onPressed: () => _pickCollection(item),
              ),
            ],
          ),
          if (collections.isEmpty)
            Text('Not in any collection',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ))
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final collection in collections)
                  InputChip(
                    label: Text(collection.name),
                    onDeleted: () => _lib.removeFromCollection(item.id, collection.id),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  String _resumeLabel(LibraryItem item) {
    final position = item.media.lastPosition;
    if (position != null && position > Duration.zero) {
      return 'Resume · ${Fmt.duration(position)}';
    }
    return 'Play';
  }

  void _play(LibraryItem item) {
    final queue = PlaybackQueue(items: [item.media]);
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PlayerScreen(queue: queue)),
    );
  }

  Future<void> _addTag(LibraryItem item) async {
    final name = await _promptText('Add tag', 'Tag name');
    if (name == null || name.trim().isEmpty || !mounted) return;
    _lib.addTagToItem(item.id, name.trim());
  }

  Future<void> _pickCollection(LibraryItem item) async {
    final collections = _lib.collections;
    if (collections.isEmpty) {
      await _createCollection();
      if (!mounted) return;
      _pickCollection(item);
      return;
    }
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              leading: const Icon(Icons.create_new_folder_outlined),
              title: const Text('New collection'),
              onTap: () => Navigator.pop(context, '__new__'),
            ),
            for (final collection in collections)
              ListTile(
                leading: const Icon(Icons.collections_bookmark_outlined),
                title: Text(collection.name),
                trailing: item.collectionIds.contains(collection.id)
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.pop(context, collection.id),
              ),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;
    if (selected == '__new__') {
      final created = await _createCollection();
      if (created != null) _lib.addToCollection(item.id, created.id);
      return;
    }
    if (item.collectionIds.contains(selected)) {
      _lib.removeFromCollection(item.id, selected);
    } else {
      _lib.addToCollection(item.id, selected);
    }
  }

  Future<dynamic> _createCollection() async {
    final name = await _promptText('New collection', 'Collection name');
    if (name == null || name.trim().isEmpty) return null;
    return _lib.createCollection(name.trim());
  }

  Future<String?> _promptText(String title, String label) {
    return showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
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
