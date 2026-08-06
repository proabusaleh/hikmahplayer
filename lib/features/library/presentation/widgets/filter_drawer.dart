import 'package:flutter/material.dart';

import '../../domain/models/library_query.dart';
import '../../../player/domain/models/media_item.dart';

/// Builds and edits a [LibraryQuery] (sort, order, media type, favourites).
class FilterDrawer extends StatefulWidget {
  const FilterDrawer({super.key, required this.initial, required this.onChanged});

  final LibraryQuery initial;
  final ValueChanged<LibraryQuery> onChanged;

  @override
  State<FilterDrawer> createState() => _FilterDrawerState();
}

class _FilterDrawerState extends State<FilterDrawer> {
  late LibraryQuery _query = widget.initial;
  late final Set<MediaType> _types = {...widget.initial.types};

  void _update({MediaType? toggleType}) {
    setState(() {
      if (toggleType != null) {
        if (_types.contains(toggleType)) {
          _types.remove(toggleType);
        } else {
          _types.add(toggleType);
        }
      }
      _query = widget.initial.copyWith(
        types: _types,
        sortBy: _sort,
        sortOrder: _order,
        favoritesOnly: _favoritesOnly,
        unwatchedOnly: _unwatchedOnly,
      );
    });
    widget.onChanged(_query);
  }

  late SortField _sort = widget.initial.sortBy;
  late SortOrder _order = widget.initial.sortOrder;
  late bool _favoritesOnly = widget.initial.favoritesOnly;
  late bool _unwatchedOnly = widget.initial.unwatchedOnly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sort & filter', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            DropdownButtonFormField<SortField>(
              initialValue: _sort,
              decoration: const InputDecoration(labelText: 'Sort by'),
              items: const [
                DropdownMenuItem(value: SortField.title, child: Text('Title')),
                DropdownMenuItem(value: SortField.dateAdded, child: Text('Date added')),
                DropdownMenuItem(value: SortField.lastPlayed, child: Text('Last played')),
                DropdownMenuItem(value: SortField.rating, child: Text('Rating')),
                DropdownMenuItem(value: SortField.year, child: Text('Year')),
                DropdownMenuItem(value: SortField.duration, child: Text('Duration')),
                DropdownMenuItem(value: SortField.fileSize, child: Text('File size')),
              ],
              onChanged: (v) {
                if (v != null) {
                  _sort = v;
                  _update();
                }
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Order'),
                const Spacer(),
                SegmentedButton<SortOrder>(
                  segments: const [
                    ButtonSegment(
                      value: SortOrder.ascending,
                      icon: Icon(Icons.arrow_upward),
                      label: Text('Asc'),
                    ),
                    ButtonSegment(
                      value: SortOrder.descending,
                      icon: Icon(Icons.arrow_downward),
                      label: Text('Desc'),
                    ),
                  ],
                  selected: {_order},
                  onSelectionChanged: (s) {
                    _order = s.first;
                    _update();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Media type', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _typeChip(MediaType.video, Icons.movie, 'Video'),
                _typeChip(MediaType.audio, Icons.music_note, 'Audio'),
                _typeChip(MediaType.image, Icons.image, 'Images'),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Favourites only'),
              value: _favoritesOnly,
              onChanged: (v) {
                _favoritesOnly = v;
                _update();
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Unwatched only'),
              value: _unwatchedOnly,
              onChanged: (v) {
                _unwatchedOnly = v;
                _update();
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    _types.clear();
                    _sort = SortField.title;
                    _order = SortOrder.ascending;
                    _favoritesOnly = false;
                    _unwatchedOnly = false;
                    _update();
                  },
                  child: const Text('Reset'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeChip(MediaType type, IconData icon, String label) {
    final selected = _types.contains(type);
    return FilterChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      selected: selected,
      onSelected: (_) => _update(toggleType: type),
    );
  }
}
