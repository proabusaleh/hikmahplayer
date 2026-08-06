import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../core/services/developer_service.dart';
import '../../../developer/domain/models/developer_models.dart';
import 'log_viewer_screen.dart';
import 'stats_screen.dart';

class DeveloperHubScreen extends StatelessWidget {
  const DeveloperHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dev = AppScope.of(context).developer;

    return Scaffold(
      appBar: AppBar(title: const Text('Developer')),
      body: ListenableBuilder(
        listenable: dev,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Section(
                title: 'REST API',
                children: [
                  SwitchListTile(
                    title: const Text('API Server'),
                    subtitle: Text(
                      dev.apiRunning
                          ? 'Running on port ${dev.apiConfig.port}'
                          : 'Stopped',
                    ),
                    value: dev.apiConfig.enabled,
                    onChanged: (_) => dev.toggleApiServer(),
                  ),
                  if (dev.apiRunning)
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: Text('Port ${dev.apiConfig.port}'),
                      subtitle: Text('Auth: ${dev.apiConfig.authMethod.name}'),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () => _showApiConfigDialog(context, dev),
                    ),
                  _BuiltInRoutesPreview(),
                ],
              ),
              _Section(
                title: 'Plugins',
                children: [
                  ListTile(
                    leading: const Icon(Icons.extension),
                    title: Text('${dev.plugins.length} installed'),
                    subtitle: Text(
                      '${dev.plugins.where((p) => p.status == PluginStatus.enabled).length} enabled',
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () => _showPluginsSheet(context, dev),
                  ),
                ],
              ),
              _Section(
                title: 'Scripting',
                children: [
                  ListTile(
                    leading: const Icon(Icons.code),
                    title: Text('${dev.scripts.length} scripts'),
                    trailing: IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      onPressed: () => _showAddScriptDialog(context, dev),
                    ),
                  ),
                ],
              ),
              _Section(
                title: 'Analytics',
                children: [
                  ListTile(
                    leading: const Icon(Icons.analytics),
                    title: const Text('Playback Statistics'),
                    subtitle: Text('${dev.mediaStats.length} media tracked'),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const StatsScreen())),
                  ),
                ],
              ),
              _Section(
                title: 'Logs',
                children: [
                  ListTile(
                    leading: const Icon(Icons.bug_report),
                    title: const Text('Log Viewer'),
                    subtitle: Text('${dev.filteredLogs.length} entries'),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const LogViewerScreen())),
                  ),
                ],
              ),
              _Section(
                title: 'Visuals',
                children: [
                  ListTile(
                    leading: const Icon(Icons.gradient),
                    title: Text('${dev.shaderPresets.length} shader presets'),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () => _showShadersSheet(context, dev),
                  ),
                ],
              ),
              _Section(
                title: 'Integrations',
                children: [
                  ListTile(
                    leading: const Icon(Icons.smart_toy),
                    title: Text('${dev.integrations.length} connected'),
                    subtitle: Text('${dev.actions.length} automation actions'),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () => _showIntegrationsSheet(context, dev),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  void _showApiConfigDialog(BuildContext context, DeveloperService dev) {
    final portController =
        TextEditingController(text: dev.apiConfig.port.toString());
    final tokenController =
        TextEditingController(text: dev.apiConfig.authToken ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('API Configuration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: portController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Port',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<ApiAuthMethod>(
              value: dev.apiConfig.authMethod,
              decoration: const InputDecoration(
                labelText: 'Auth Method',
                border: OutlineInputBorder(),
              ),
              items: ApiAuthMethod.values
                  .map((m) => DropdownMenuItem(value: m, child: Text(m.name)))
                  .toList(),
              onChanged: (v) {
                if (v != null) dev.setApiAuth(v);
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: tokenController,
              decoration: const InputDecoration(
                labelText: 'Auth Token',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final port = int.tryParse(portController.text) ?? 8080;
              dev.setApiPort(port);
              dev.setApiAuth(dev.apiConfig.authMethod,
                  token: tokenController.text);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showPluginsSheet(BuildContext context, DeveloperService dev) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        builder: (ctx, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Plugins',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (dev.plugins.isEmpty) const Text('No plugins installed.'),
            for (final p in dev.plugins)
              ListTile(
                leading: Icon(
                  p.status == PluginStatus.enabled
                      ? Icons.check_circle
                      : Icons.extension,
                  color: p.status == PluginStatus.enabled ? Colors.green : null,
                ),
                title: Text(p.manifest.name),
                subtitle: Text('v${p.manifest.version} by ${p.manifest.author}'),
                trailing: Switch(
                  value: p.status == PluginStatus.enabled,
                  onChanged: (_) => dev.togglePlugin(p.manifest.id),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddScriptDialog(BuildContext context, DeveloperService dev) {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    ScriptLanguage lang = ScriptLanguage.dart;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('New Script'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<ScriptLanguage>(
                value: lang,
                decoration: const InputDecoration(
                  labelText: 'Language',
                  border: OutlineInputBorder(),
                ),
                items: ScriptLanguage.values
                    .map((l) =>
                        DropdownMenuItem(value: l, child: Text(l.name)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => lang = v);
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: codeController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Code',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;
                dev.addScript(
                  name: nameController.text.trim(),
                  code: codeController.text,
                  language: lang,
                );
                Navigator.pop(ctx);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showShadersSheet(BuildContext context, DeveloperService dev) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        builder: (ctx, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Shader Presets',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (dev.shaderPresets.isEmpty) const Text('No shader presets.'),
            for (final s in dev.shaderPresets)
              ListTile(
                leading: Icon(
                  s.enabled ? Icons.check_circle : Icons.gradient,
                  color: s.enabled ? Colors.green : null,
                ),
                title: Text(s.name),
                subtitle: Text('${s.parameters.length} parameters'),
                trailing: Switch(
                  value: s.enabled,
                  onChanged: (_) => dev.toggleShaderPreset(s.id),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showIntegrationsSheet(BuildContext context, DeveloperService dev) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        builder: (ctx, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Integrations',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            for (final type in IntegrationType.values)
              _IntegrationTile(
                type: type,
                integration: dev.integrations
                    .where((i) => i.type == type)
                    .firstOrNull,
                onToggle: () => dev.toggleIntegration(type),
              ),
          ],
        ),
      ),
    );
  }
}

class _BuiltInRoutesPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: const Text('Built-in Routes'),
      children: ApiServerConfig.builtInRoutes
          .map((r) => ListTile(
                dense: true,
                leading: Text(
                  r.method,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: r.method == 'GET' ? Colors.green : Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                title: Text(r.path, style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
                subtitle: Text(r.description),
              ))
          .toList(),
    );
  }
}

class _IntegrationTile extends StatelessWidget {
  const _IntegrationTile({
    required this.type,
    required this.integration,
    required this.onToggle,
  });

  final IntegrationType type;
  final AutomationIntegration? integration;
  final VoidCallback onToggle;

  static const _icons = {
    IntegrationType.homeAssistant: Icons.home,
    IntegrationType.tasker: Icons.android,
    IntegrationType.shortcuts: Icons.shortcut,
    IntegrationType.mqtt: Icons.swap_horiz,
    IntegrationType.webhook: Icons.http,
  };

  static const _labels = {
    IntegrationType.homeAssistant: 'Home Assistant',
    IntegrationType.tasker: 'Tasker',
    IntegrationType.shortcuts: 'iOS Shortcuts',
    IntegrationType.mqtt: 'MQTT',
    IntegrationType.webhook: 'Webhook',
  };

  @override
  Widget build(BuildContext context) {
    final connected = integration?.status == IntegrationStatus.connected;

    return ListTile(
      leading: Icon(_icons[type], color: connected ? Colors.green : null),
      title: Text(_labels[type] ?? type.name),
      subtitle: Text(connected ? 'Connected' : 'Not connected'),
      trailing: Switch(value: connected, onChanged: (_) => onToggle()),
    );
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
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 4),
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
