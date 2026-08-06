import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';
import 'data_control_screen.dart';
import 'incognito_screen.dart';
import 'network_control_screen.dart';
import 'permissions_screen.dart';
import 'vault_screen.dart';

class PrivacyDashboardScreen extends StatelessWidget {
  const PrivacyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final privacy = AppScope.of(context).privacy;

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Security')),
      body: ListenableBuilder(
        listenable: privacy,
        builder: (context, _) {
          final dash = privacy.dashboard();

          return ListView(
            children: [
              _SummaryHeader(dash: dash),
              const SizedBox(height: 8),
              if (privacy.isIncognito)
                const _IncognitoBanner(),
              _Section(
                title: 'Security',
                tiles: [
                  _DashboardTile(
                    icon: Icons.shield_outlined,
                    title: 'Private Vault',
                    subtitle: privacy.vaultConfig.enabled
                        ? '${privacy.vaultItems.length} items secured'
                        : 'Not configured',
                    trailing: privacy.vaultConfig.enabled
                        ? const Icon(Icons.lock_outline, size: 20, color: Colors.green)
                        : const Icon(Icons.lock_open, size: 20),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const VaultScreen()),
                    ),
                  ),
                  _DashboardTile(
                    icon: Icons.visibility_off_outlined,
                    title: 'Incognito Mode',
                    subtitle: privacy.isIncognito ? 'Active' : 'Inactive',
                    trailing: privacy.isIncognito
                        ? const Icon(Icons.theater_comedy, size: 20, color: Colors.orange)
                        : const Icon(Icons.chevron_right, size: 20),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const IncognitoScreen()),
                    ),
                  ),
                ],
              ),
              _Section(
                title: 'Data Control',
                tiles: [
                  _DashboardTile(
                    icon: Icons.security,
                    title: 'Permissions',
                    subtitle: 'Granular feature access',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PermissionsScreen()),
                    ),
                  ),
                  _DashboardTile(
                    icon: Icons.wifi_off_outlined,
                    title: 'Network Access',
                    subtitle: '${dash.blockedNetworkSources} sources blocked',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NetworkControlScreen()),
                    ),
                  ),
                  _DashboardTile(
                    icon: Icons.import_export,
                    title: 'Export / Import / Delete',
                    subtitle: dash.lastExportAt != null
                        ? 'Last export: ${_formatDate(dash.lastExportAt!)}'
                        : 'No exports yet',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DataControlScreen()),
                    ),
                  ),
                ],
              ),
              _Section(
                title: 'Data Stores',
                tiles: [
                  for (final store in dash.localDataStores)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.storage, size: 20),
                      title: Text(store, style: const TextStyle(fontSize: 14)),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.dash});

  final dynamic dash;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.privacy_tip, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Privacy Overview',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Stat(
                value: '${dash.watchHistoryCount}',
                label: 'History',
                icon: Icons.history,
              ),
              _Stat(
                value: '${dash.vaultItemCount}',
                label: 'Vault',
                icon: Icons.lock,
              ),
              _Stat(
                value: '${dash.storedMediaCount}',
                label: 'Media',
                icon: Icons.folder,
              ),
              _Stat(
                value: '${dash.containerCount}',
                label: 'Encrypted',
                icon: Icons.enhanced_encryption,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!dash.telemetryEnabled)
            Row(
              children: [
                const Icon(Icons.check_circle, size: 16, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  'Telemetry disabled',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.green),
                ),
              ],
            )
          else
            Row(
              children: [
                const Icon(Icons.warning_amber, size: 16, color: Colors.orange),
                const SizedBox(width: 4),
                Text(
                  'Telemetry enabled',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.icon});

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onPrimaryContainer),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onPrimaryContainer.withAlpha(180),
          ),
        ),
      ],
    );
  }
}

class _IncognitoBanner extends StatelessWidget {
  const _IncognitoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withAlpha(80)),
      ),
      child: Row(
        children: const [
          Icon(Icons.theater_comedy, color: Colors.orange, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Incognito active — history and recommendations are paused',
              style: TextStyle(color: Colors.orange, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.tiles});

  final String title;
  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
        ...tiles,
      ],
    );
  }
}

class _DashboardTile extends StatelessWidget {
  const _DashboardTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing ?? const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
