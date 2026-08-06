import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../core/services/continuity_service.dart';
import '../../../continuity/domain/models/device_sync.dart';

class ContinuityScreen extends StatelessWidget {
  const ContinuityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final continuity = AppScope.of(context).continuity;

    return Scaffold(
      appBar: AppBar(title: const Text('Cross-Device')),
      body: ListenableBuilder(
        listenable: continuity,
        builder: (context, _) {
          final local = continuity.localDevice;
          final handoffs = continuity.handoffs;
          final synced = continuity.lastSyncedState;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Section(
                title: 'Local Device',
                children: [
                  if (local != null)
                    _DeviceTile(device: local, isLocal: true)
                  else
                    ListTile(
                      leading: const Icon(Icons.add_circle_outline),
                      title: const Text('Register This Device'),
                      subtitle: const Text('Set up this device for cross-device sync'),
                      onTap: () => _showRegisterDialog(context, continuity),
                    ),
                ],
              ),
              _Section(
                title: 'Paired Devices',
                children: [
                  if (continuity.remoteDevices.isEmpty)
                    ListTile(
                      leading: const Icon(Icons.devices_other),
                      title: const Text('No paired devices'),
                      subtitle: const Text('Discover nearby devices to enable handoff'),
                    )
                  else
                    for (final device in continuity.remoteDevices)
                      _DeviceTile(
                        device: device,
                        onHandoff: () => _showHandoffDialog(context, continuity, device),
                        onRemote: () => _showRemoteDialog(context, continuity, device),
                      ),
                ],
              ),
              if (synced != null) ...[
                _Section(
                  title: 'Last Sync',
                  children: [
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.sync),
                        title: Text('Position synced'),
                        subtitle: Text(
                          'Device: ${synced.deviceId}\n'
                          'Media: ${synced.mediaId}\n'
                          'Position: ${_formatDuration(synced.positionSeconds)}\n'
                          '${_formatTime(synced.syncedAt)}',
                        ),
                        isThreeLine: true,
                      ),
                    ),
                  ],
                ),
              ],
              if (handoffs.isNotEmpty) ...[
                _Section(
                  title: 'Handoff History',
                  children: [
                    for (final h in handoffs.take(10))
                      _HandoffTile(handoff: h),
                  ],
                ),
              ],
              _Section(
                title: 'Clipboard',
                children: [
                  ListTile(
                    leading: const Icon(Icons.content_paste),
                    title: const Text('Shared Clipboard'),
                    subtitle: Text('${continuity.clipboard.length} items'),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () => _showClipboard(context, continuity),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRegisterDialog(BuildContext context, ContinuityService continuity) {
    final nameController = TextEditingController();
    final platformController = TextEditingController(text: 'unknown');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Register Device'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Device name',
                hintText: 'My Phone',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: platformController,
              decoration: const InputDecoration(
                labelText: 'Platform',
                hintText: 'android / ios / desktop',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              final id = 'device-${DateTime.now().microsecondsSinceEpoch}';
              continuity.setLocalDevice(id, name, platformController.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Register'),
          ),
        ],
      ),
    );
  }

  void _showHandoffDialog(
    BuildContext context,
    ContinuityService continuity,
    DeviceProfile device,
  ) {
    final posController = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Handoff to ${device.name}'),
        content: TextField(
          controller: posController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Resume from position (seconds)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final pos = double.tryParse(posController.text) ?? 0;
              continuity.initiateHandoff(
                toDeviceId: device.id,
                mediaId: 'current-media',
                positionSeconds: pos,
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Handoff initiated to ${device.name}')),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showRemoteDialog(
    BuildContext context,
    ContinuityService continuity,
    DeviceProfile device,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Remote: ${device.name}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          for (final cmd in RemoteCommandType.values)
            ListTile(
              leading: Icon(_commandIcon(cmd)),
              title: Text(cmd.name),
              onTap: () {
                continuity.sendCommand(type: cmd, targetDeviceId: device.id);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Sent ${cmd.name} to ${device.name}')),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showClipboard(BuildContext context, ContinuityService continuity) {
    final entries = continuity.clipboard;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        builder: (ctx, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Shared Clipboard',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (entries.isEmpty) const Text('No clipboard entries.'),
            for (final e in entries)
              Card(
                child: ListTile(
                  leading: Icon(_clipIcon(e.type)),
                  title: Text(e.content, maxLines: 2),
                  subtitle: Text('From: ${e.sourceDeviceId}'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static IconData _commandIcon(RemoteCommandType type) {
    return switch (type) {
      RemoteCommandType.play => Icons.play_arrow,
      RemoteCommandType.pause => Icons.pause,
      RemoteCommandType.seek => Icons.fast_forward,
      RemoteCommandType.skipNext => Icons.skip_next,
      RemoteCommandType.skipPrevious => Icons.skip_previous,
      RemoteCommandType.stop => Icons.stop,
      RemoteCommandType.setVolume => Icons.volume_up,
    };
  }

  static IconData _clipIcon(ClipboardEntryType type) {
    return switch (type) {
      ClipboardEntryType.text => Icons.text_fields,
      ClipboardEntryType.link => Icons.link,
      ClipboardEntryType.timestamp => Icons.access_time,
      ClipboardEntryType.note => Icons.note,
    };
  }

  static String _formatDuration(double seconds) {
    final m = (seconds / 60).floor();
    final s = (seconds % 60).round();
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  static String _formatTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({
    required this.device,
    this.isLocal = false,
    this.onHandoff,
    this.onRemote,
  });

  final DeviceProfile device;
  final bool isLocal;
  final VoidCallback? onHandoff;
  final VoidCallback? onRemote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        leading: Icon(
          isLocal ? Icons.phone_android : Icons.devices_other,
          color: device.isOnline ? theme.colorScheme.primary : theme.colorScheme.outline,
        ),
        title: Row(
          children: [
            Text(device.name),
            if (isLocal) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('This', style: theme.textTheme.labelSmall),
              ),
            ],
          ],
        ),
        subtitle: Text(
          '${device.platform} · ${device.isOnline ? 'Online' : 'Offline'}',
        ),
        trailing: isLocal
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onRemote != null)
                    IconButton(
                      icon: const Icon(Icons.settings_remote, size: 20),
                      tooltip: 'Remote control',
                      onPressed: onRemote,
                    ),
                  if (onHandoff != null)
                    IconButton(
                      icon: const Icon(Icons.swap_horiz, size: 20),
                      tooltip: 'Handoff',
                      onPressed: onHandoff,
                    ),
                ],
              ),
      ),
    );
  }
}

class _HandoffTile extends StatelessWidget {
  const _HandoffTile({required this.handoff});

  final HandoffSession handoff;

  @override
  Widget build(BuildContext context) {
    final isCompleted = handoff.state == HandoffState.completed;
    final isFailed = handoff.state == HandoffState.failed;

    return ListTile(
      leading: Icon(
        isCompleted ? Icons.check_circle : (isFailed ? Icons.error : Icons.swap_horiz),
        color: isCompleted ? Colors.green : (isFailed ? Colors.red : null),
      ),
      title: Text('${handoff.fromDeviceId} → ${handoff.toDeviceId}'),
      subtitle: Text(
        'Position: ${_formatDuration(handoff.positionSeconds)} · ${handoff.state.name}',
      ),
    );
  }

  static String _formatDuration(double seconds) {
    final m = (seconds / 60).floor();
    final s = (seconds % 60).round();
    return '$m:${s.toString().padLeft(2, '0')}';
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
