import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../core/services/privacy_service.dart';

class DataControlScreen extends StatelessWidget {
  const DataControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final privacy = AppScope.of(context).privacy;

    return Scaffold(
      appBar: AppBar(title: const Text('Data Control')),
      body: ListenableBuilder(
        listenable: privacy,
        builder: (context, _) {
          final dash = privacy.dashboard();

          return ListView(
            children: [
              _Section(
                title: 'Export',
                children: [
                  ListTile(
                    leading: const Icon(Icons.upload_file),
                    title: const Text('Export All Data'),
                    subtitle: Text(
                      dash.lastExportAt != null
                          ? 'Last: ${_formatDate(dash.lastExportAt!)}'
                          : 'Encrypt and export all settings and history',
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () => _showExportDialog(context, privacy),
                  ),
                ],
              ),
              _Section(
                title: 'Import',
                children: [
                  ListTile(
                    leading: const Icon(Icons.download),
                    title: const Text('Import Data'),
                    subtitle: const Text('Restore from an encrypted backup'),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () => _showImportDialog(context, privacy),
                  ),
                ],
              ),
              _Section(
                title: 'Danger Zone',
                children: [
                  ListTile(
                    leading: const Icon(Icons.delete_forever, color: Colors.red),
                    title: const Text('Delete All Data', style: TextStyle(color: Colors.red)),
                    subtitle: const Text('Permanently erase all history, vault items, and containers'),
                    onTap: () => _showDeleteDialog(context, privacy),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  void _showExportDialog(BuildContext context, PrivacyService privacy) {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export All Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Your data will be encrypted with a password. '
              'You will need this password to import it later.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Encryption password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (passwordController.text.length < 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password must be at least 4 characters')),
                );
                return;
              }
              if (passwordController.text != confirmController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }
              final result = privacy.exportAllData(password: passwordController.text);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Exported ${result.itemCount} items (${result.itemCount} items)'),
                ),
              );
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context, PrivacyService privacy) {
    final passwordController = TextEditingController();
    final blobController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Paste your encrypted export blob and enter the password.'),
            const SizedBox(height: 16),
            TextField(
              controller: blobController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Encrypted blob',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final result = privacy.importAllData(
                blobController.text,
                password: passwordController.text,
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result.success
                      ? 'Imported ${result.itemCount} items'
                      : 'Import failed: ${result.error}'),
                ),
              );
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, PrivacyService privacy) {
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber, color: Colors.red, size: 48),
        title: const Text('Delete All Data?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This will permanently erase all watch history, vault items, '
              'encrypted containers, and session data. This cannot be undone.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(
                labelText: 'Type DELETE to confirm',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (confirmController.text != 'DELETE') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Type DELETE to confirm')),
                );
                return;
              }
              privacy.deleteAllData();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All data deleted')),
              );
            },
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

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
        ...children,
      ],
    );
  }
}
