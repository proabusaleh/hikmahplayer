import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../core/services/privacy_service.dart';
import '../../../privacy/domain/models/data_permission.dart';

class NetworkControlScreen extends StatelessWidget {
  const NetworkControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final privacy = AppScope.of(context).privacy;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Access'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Block a host',
            onPressed: () => _showAddDialog(context, privacy),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: privacy,
        builder: (context, _) {
          final blocked = privacy.settings.blockedNetworkSources;
          final globalAllowed = privacy.allows(DataPermission.networkAccess);

          return ListView(
            children: [
              SwitchListTile(
                title: const Text('Network Access'),
                subtitle: const Text('Global toggle for all network access'),
                value: globalAllowed,
                onChanged: (v) => privacy.setPermission(DataPermission.networkAccess, v),
              ),
              if (!globalAllowed)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.warning_amber, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'All network access is blocked globally',
                          style: TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              const Divider(height: 32),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  'Blocked Sources',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ),
              if (blocked.isEmpty)
                ListTile(
                  leading: Icon(Icons.check_circle, color: Theme.of(context).colorScheme.outline),
                  title: const Text('No blocked sources'),
                  subtitle: const Text('All media sources have network access'),
                )
              else
                for (final host in blocked)
                  ListTile(
                    leading: const Icon(Icons.block),
                    title: Text(host),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      tooltip: 'Unblock',
                      onPressed: () => privacy.unblockNetworkSource(host),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }

  void _showAddDialog(BuildContext context, PrivacyService privacy) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Block Source'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Host or domain',
            hintText: 'example.com',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final host = controller.text.trim();
              if (host.isEmpty) return;
              privacy.blockNetworkSource(host);
              Navigator.pop(ctx);
            },
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }
}
