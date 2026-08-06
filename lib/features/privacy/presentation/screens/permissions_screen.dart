import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';
import '../../../privacy/domain/models/data_permission.dart';

class PermissionsScreen extends StatelessWidget {
  const PermissionsScreen({super.key});

  static const _titles = {
    DataPermission.onDeviceAi: 'On-Device AI',
    DataPermission.cloudAi: 'Cloud AI',
    DataPermission.telemetry: 'Telemetry',
    DataPermission.watchHistory: 'Watch History',
    DataPermission.recommendations: 'Recommendations',
    DataPermission.privateVault: 'Private Vault',
    DataPermission.networkAccess: 'Network Access',
    DataPermission.cloudSync: 'Cloud Sync',
  };

  static const _descriptions = {
    DataPermission.onDeviceAi: 'Runs locally on this device; nothing is uploaded.',
    DataPermission.cloudAi: 'Off by default. Enabling sends content to a cloud provider.',
    DataPermission.telemetry: 'No telemetry is collected unless you opt in.',
    DataPermission.watchHistory: 'Stored only on this device.',
    DataPermission.recommendations: 'Derived from your local watch history.',
    DataPermission.privateVault: 'Hidden, PIN/biometric protected media.',
    DataPermission.networkAccess: 'Per media source; blockable individually.',
    DataPermission.cloudSync: 'Cloud sync is opt-in.',
  };

  static const _icons = {
    DataPermission.onDeviceAi: Icons.phone_android,
    DataPermission.cloudAi: Icons.cloud_outlined,
    DataPermission.telemetry: Icons.analytics_outlined,
    DataPermission.watchHistory: Icons.history,
    DataPermission.recommendations: Icons.recommend_outlined,
    DataPermission.privateVault: Icons.lock,
    DataPermission.networkAccess: Icons.wifi,
    DataPermission.cloudSync: Icons.sync,
  };

  @override
  Widget build(BuildContext context) {
    final privacy = AppScope.of(context).privacy;

    return Scaffold(
      appBar: AppBar(title: const Text('Permissions')),
      body: ListenableBuilder(
        listenable: privacy,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Text(
                  'Control what each feature is allowed to do. Disabling a permission restricts the feature immediately.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ),
              for (final perm in DataPermission.values) ...[
                _PermissionTile(
                  permission: perm,
                  icon: _icons[perm] ?? Icons.help_outline,
                  label: _titles[perm] ?? perm.name,
                  description: _descriptions[perm] ?? '',
                  allowed: privacy.allows(perm),
                  onChanged: (allowed) => privacy.setPermission(perm, allowed),
                ),
                if (perm != DataPermission.values.last) const Divider(height: 1, indent: 72),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.permission,
    required this.icon,
    required this.label,
    required this.description,
    required this.allowed,
    required this.onChanged,
  });

  final DataPermission permission;
  final IconData icon;
  final String label;
  final String description;
  final bool allowed;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(icon, color: allowed ? theme.colorScheme.primary : theme.colorScheme.outline),
      title: Text(label),
      subtitle: Text(description, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: Switch.adaptive(
        value: allowed,
        onChanged: onChanged,
      ),
      onTap: () => onChanged(!allowed),
    );
  }
}
