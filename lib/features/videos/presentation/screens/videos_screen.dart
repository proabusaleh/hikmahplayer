import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../core/storage/media_type.dart';
import '../../../../core/storage/repositories/media_repository.dart';
import '../../../../presentation/providers/player_provider.dart' show playerMediaFromRow;
import '../../../../shared/utils/format.dart';
import '../../../player/domain/models/playback_queue.dart';
import '../../../player/presentation/screens/player_screen.dart';

/// The on-device video library.
///
/// Streams the persisted [MediaItems] rows of the database (populated by
/// [MediaScanService]) and plays them through the shared engine via
/// [PlayerScreen]. The app bar action triggers an on-demand re-scan.
class VideosScreen extends StatefulWidget {
  const VideosScreen({super.key});

  @override
  State<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends State<VideosScreen> {
  bool _scanning = false;

  Future<void> _rescan() async {
    if (_scanning) return;
    setState(() => _scanning = true);
    final services = AppScope.of(context);
    final result = await services.mediaScan.scanAll();
    if (!mounted) return;
    setState(() => _scanning = false);
    final found = result.videosFound;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          found > 0
              ? 'Found $found video${found == 1 ? '' : 's'}'
              : 'No new videos found',
        ),
      ),
    );
  }

  void _play(MediaItem row) {
    final queue = PlaybackQueue(items: [playerMediaFromRow(row)]);
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PlayerScreen(queue: queue)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Videos'),
        actions: [
          if (_scanning)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              tooltip: 'Rescan device',
              icon: const Icon(Icons.refresh),
              onPressed: _rescan,
            ),
        ],
      ),
      body: StreamBuilder<List<MediaItem>>(
        stream: AppScope.of(context).media.watchByType(HikmahMediaType.video),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _StatusMessage(
              icon: Icons.error_outline,
              title: 'Something went wrong',
              message: '${snapshot.error}',
              action: _rescanButton(),
            );
          }
          final items = snapshot.data ?? const <MediaItem>[];
          if (items.isEmpty) {
            return _StatusMessage(
              icon: Icons.movie_outlined,
              title: 'No videos yet',
              message: 'Videos stored on your device will appear here after '
                  'the library scanner runs.',
              action: _rescanButton(),
            );
          }
          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            itemBuilder: (context, index) =>
                _VideoTile(row: items[index], theme: theme, onTap: _play),
          );
        },
      ),
    );
  }

  Widget _rescanButton() => Padding(
        padding: const EdgeInsets.only(top: 20),
        child: OutlinedButton.icon(
          onPressed: _scanning ? null : _rescan,
          icon: const Icon(Icons.refresh),
          label: const Text('Rescan device'),
        ),
      );
}

class _VideoTile extends StatelessWidget {
  const _VideoTile({
    required this.row,
    required this.theme,
    required this.onTap,
  });

  final MediaItem row;
  final ThemeData theme;
  final ValueChanged<MediaItem> onTap;

  @override
  Widget build(BuildContext context) {
    final title =
        (row.title != null && row.title!.isNotEmpty) ? row.title! : row.fileName;
    final duration =
        row.durationMs > 0 ? Duration(milliseconds: row.durationMs) : null;
    final detail = <String>[
      if (duration != null) Fmt.duration(duration),
      if (row.folderName != null && row.folderName!.isNotEmpty) row.folderName!,
    ];

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 104,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.35),
              theme.colorScheme.primary.withValues(alpha: 0.15),
            ],
          ),
        ),
        child: Icon(
          Icons.movie_outlined,
          color: theme.colorScheme.primary,
        ),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleMedium,
      ),
      subtitle: detail.isNotEmpty
          ? Text(
              detail.join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      trailing: Icon(
        Icons.play_circle_outline,
        color: theme.colorScheme.primary,
      ),
      onTap: () => onTap(row),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 4),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}