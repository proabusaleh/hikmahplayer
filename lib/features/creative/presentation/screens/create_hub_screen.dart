import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../core/services/export_service.dart';
import 'clip_editor_screen.dart';
import 'export_screen.dart';
import 'screenshot_editor_screen.dart';

class CreateHubScreen extends StatefulWidget {
  const CreateHubScreen({super.key});

  @override
  State<CreateHubScreen> createState() => _CreateHubScreenState();
}

class _CreateHubScreenState extends State<CreateHubScreen> {
  ExportService? _export;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _export ??= AppScope.of(context).export;
    _export!.addListener(_onChanged);
  }

  @override
  void dispose() {
    _export?.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  ExportService get _svc => _export!;

  @override
  Widget build(BuildContext context) {
    final job = _svc.activeJob.value;
    final clipCount = _svc.clips.value.length;
    final collectionCount = _svc.collections.value.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Create')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (job != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Exporting… ${(job.progress * 100).toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Library', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _Stat(label: '$clipCount clips', icon: Icons.content_cut),
                      const SizedBox(width: 24),
                      _Stat(
                        label: '$collectionCount collections',
                        icon: Icons.collections_bookmark,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Tools', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _ToolTile(
            icon: Icons.content_cut,
            title: 'Clip Editor',
            subtitle: 'Trim, split & merge',
            route: MaterialPageRoute<void>(
              builder: (_) => const ClipEditorScreen(),
            ),
          ),
          _ToolTile(
            icon: Icons.ios_share,
            title: 'Export',
            subtitle: 'GIF, MP4, WebM, frames',
            route: MaterialPageRoute<void>(
              builder: (_) => const ExportScreen(),
            ),
          ),
          _ToolTile(
            icon: Icons.photo_camera_back,
            title: 'Screenshot Editor',
            subtitle: 'Annotate & share frames',
            route: MaterialPageRoute<void>(
              builder: (_) => const ScreenshotEditorScreen(),
            ),
          ),
          _ToolTile(
            icon: Icons.branding_watermark,
            title: 'Watermark & Subtitle Burn',
            subtitle: 'Overlay text on exports',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.route,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final MaterialPageRoute<void>? route;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap ?? (route != null ? () => Navigator.push(context, route!) : null),
      ),
    );
  }
}
