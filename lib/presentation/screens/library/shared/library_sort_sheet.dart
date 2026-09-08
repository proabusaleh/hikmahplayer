import 'package:flutter/material.dart';

import 'library_sort.dart';

/// Bottom sheet to pick the sort field and direction for a library.
Future<LibrarySort?> showLibrarySortSheet(
  BuildContext context, {
  required LibrarySort current,
  List<LibrarySortField> fields = const [
    LibrarySortField.name,
    LibrarySortField.dateAdded,
    LibrarySortField.dateModified,
    LibrarySortField.size,
    LibrarySortField.duration,
    LibrarySortField.lastPlayed,
    LibrarySortField.playCount,
  ],
}) {
  return showModalBottomSheet<LibrarySort>(
    context: context,
    showDragHandle: true,
    builder: (context) => _LibrarySortSheet(current: current, fields: fields),
  );
}

class _LibrarySortSheet extends StatefulWidget {
  const _LibrarySortSheet({required this.current, required this.fields});

  final LibrarySort current;
  final List<LibrarySortField> fields;

  @override
  State<_LibrarySortSheet> createState() => _LibrarySortSheetState();
}

class _LibrarySortSheetState extends State<_LibrarySortSheet> {
  late LibrarySortField _field = widget.current.field;
  late LibrarySortOrder _order = widget.current.order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(
              'Sort by',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          for (final field in widget.fields)
            ListTile(
              dense: true,
              leading: Icon(
                _field == field ? Icons.radio_button_checked : Icons.radio_button_off,
                color: _field == field ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              ),
              title: Text(
                field.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: _field == field ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              onTap: () => setState(() => _field = field),
            ),
          const Divider(height: 1),
          ListTile(
            dense: true,
            leading: Icon(
              _order == LibrarySortOrder.ascending
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              color: theme.colorScheme.primary,
            ),
            title: Text(
              _order == LibrarySortOrder.ascending
                  ? 'Ascending (A → Z)'
                  : 'Descending (Z → A)',
            ),
            trailing: Switch(
              value: _order == LibrarySortOrder.descending,
              onChanged: (down) => setState(() {
                _order = down
                    ? LibrarySortOrder.descending
                    : LibrarySortOrder.ascending;
              }),
            ),
            onTap: () => setState(() {
              _order = _order == LibrarySortOrder.ascending
                  ? LibrarySortOrder.descending
                  : LibrarySortOrder.ascending;
            }),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () =>
                    Navigator.pop(context, LibrarySort(field: _field, order: _order)),
                child: const Text('Apply sort'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}