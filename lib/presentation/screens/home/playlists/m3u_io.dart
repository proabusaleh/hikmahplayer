import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/m3u/m3u_codec.dart';
import '../../../../core/storage/repositories/media_repository.dart';
import '../../../../presentation/providers/library_provider.dart';
import '../../../../presentation/providers/media_provider.dart';
import '../../../../presentation/providers/playlist_library_provider.dart';
import '../../../../presentation/providers/services_provider.dart';

/// Default parent folder for exported `.m3u` playlist files.
const String defaultM3uExportDirectory = '/storage/emulated/0/Hikmah/Exports';

/// Asks the user for a filesystem path. Returns `null` when cancelled.
Future<String?> promptForPath(
  BuildContext context, {
  required String title,
  required String hint,
  required String confirmLabel,
  required IconData icon,
  String? initial,
}) async {
  final controller = TextEditingController(text: initial ?? '');
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return (result == null || result.isEmpty) ? null : result;
}

/// Parses an `.m3u` file located at [path], matches its entries against the
/// current library and stores them in a newly-created playlist.
Future<void> importM3uIntoNewPlaylist(
  BuildContext context,
  WidgetRef ref,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final path = await promptForPath(
    context,
    title: 'Import M3U Playlist',
    hint: '/path/to/playlist.m3u',
    confirmLabel: 'Import',
    icon: Icons.file_open_outlined,
  );
  if (path == null) return;

  try {
    final file = File(path);
    if (!file.existsSync()) {
      throw FileSystemException('File not found', path);
    }
    final entries = parseM3u(await file.readAsString());
    if (entries.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No playable entries found in the file')),
      );
      return;
    }

    final library =
        ref.read(mediaItemsStreamProvider).valueOrNull ?? const <MediaItem>[];
    final matched = matchM3uEntries(library, entries);
    if (matched.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('None of the entries matched your library'),
        ),
      );
      return;
    }

    final services = ref.read(appServicesProvider);
    const uuid = Uuid();
    final id = uuid.v4();
    await services.playlists.create(
      id: id,
      name: _playlistNameFromFile(path),
      description: 'Imported from ${file.path}',
    );
    for (final item in matched) {
      await services.playlists.addMedia(
        itemId: uuid.v4(),
        playlistId: id,
        mediaId: item.id,
      );
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Imported ${matched.length} item${matched.length == 1 ? '' : 's'} '
          'from ${entries.length} entries',
        ),
      ),
    );
  } catch (error) {
    messenger.showSnackBar(SnackBar(content: Text('Import failed: $error')));
  }
}

/// Serializes [playlistId]'s items to an `.m3u` file inside a chosen folder.
Future<void> exportPlaylistToM3u(
  BuildContext context,
  WidgetRef ref, {
  required String playlistId,
  required String playlistName,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final dir = await promptForPath(
    context,
    title: 'Export "$playlistName"',
    hint: 'Playlist export folder',
    confirmLabel: 'Export',
    icon: Icons.save_outlined,
    initial: defaultM3uExportDirectory,
  );
  if (dir == null) return;

  final items =
      ref.read(playlistLibraryItemsProvider(playlistId)).valueOrNull ??
          const <MediaItem>[];
  if (items.isEmpty) {
    messenger.showSnackBar(
      const SnackBar(content: Text('This playlist is empty — nothing to export')),
    );
    return;
  }

  try {
    final m3u = buildM3u([
      for (final item in items)
        M3uEntry(
          path: item.filePath,
          durationSeconds: item.durationMs ~/ 1000,
          title: item.displayTitle,
        ),
    ]);
    final directory = Directory(dir);
    directory.createSync(recursive: true);
    final safeName = playlistName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final outputPath = '${directory.path}/$safeName.m3u';
    File(outputPath).writeAsStringSync(m3u);
    messenger.showSnackBar(
      SnackBar(content: Text('Exported ${items.length} items to $outputPath')),
    );
  } catch (error) {
    messenger.showSnackBar(SnackBar(content: Text('Export failed: $error')));
  }
}

String _playlistNameFromFile(String path) {
  final index = path.lastIndexOf(RegExp(r'[/\\]'));
  var name = path.substring(index + 1);
  final dot = name.lastIndexOf('.');
  if (dot > 0) name = name.substring(0, dot);
  return name.trim().isEmpty ? 'Imported Playlist' : name;
}