import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../core/storage/storage_locations.dart';
import '../../../../shared/utils/format.dart';

class StorageSettingsScreen extends StatefulWidget {
  const StorageSettingsScreen({super.key});

  @override
  State<StorageSettingsScreen> createState() => _StorageSettingsScreenState();
}

class _StorageSettingsScreenState extends State<StorageSettingsScreen> {
  int? _thumbnailBytes;
  bool _clearing = false;

  @override
  void initState() {
    super.initState();
    StorageLocations.thumbnailCacheSize().then((v) {
      if (mounted) setState(() => _thumbnailBytes = v);
    });
  }

  Future<void> _clearTemp() async {
    setState(() => _clearing = true);
    await StorageLocations.clearTemp();
    if (!mounted) return;
    setState(() => _clearing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Temporary files cleared')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = AppScope.of(context).prefs;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Storage')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Thumbnail cache'),
            subtitle: Text(
              '${Fmt.bytes(_thumbnailBytes)} of '
              '${Fmt.bytes(StorageLocations.maxThumbnailCacheBytes)} used',
            ),
          ),
          ListTile(
            title: const Text('Clear temporary files'),
            subtitle: const Text('Session files are removed'),
            trailing: _clearing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_sweep_outlined),
            onTap: _clearing ? null : _clearTemp,
          ),
          SwitchListTile(
            title: const Text('Incognito mode'),
            subtitle: const Text('Pause history recording'),
            value: prefs.incognitoMode,
            onChanged: (v) => setState(() => prefs.incognitoMode = v),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Cache is evicted least-recently-used when it exceeds the '
              'limit. The database lives in app-private storage.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
