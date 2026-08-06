import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../core/services/audio_service.dart';
import '../../domain/models/routing.dart';

class AudioRoutingScreen extends StatefulWidget {
  const AudioRoutingScreen({super.key});

  @override
  State<AudioRoutingScreen> createState() => _AudioRoutingScreenState();
}

class _AudioRoutingScreenState extends State<AudioRoutingScreen> {
  AudioService? _audio;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_audio == null) {
      _audio = AppScope.of(context).audio;
      _audio!.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    _audio?.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  AudioService get _svc => _audio!;

  @override
  Widget build(BuildContext context) {
    final matrix = _svc.routing;
    final apps = _uniqueApps(matrix);

    return Scaffold(
      appBar: AppBar(title: const Text('Audio Routing')),
      body: matrix.routes.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cell_tower,
                      size: 72, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 16),
                  Text('No routes configured',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Add routes to direct audio from apps to output devices.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _addRoute,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Route'),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final app in apps) ...[
                  Text(app,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          )),
                  const SizedBox(height: 4),
                  Card(
                    child: Column(
                      children: [
                        for (final route in matrix.routesFor(app))
                          ListTile(
                            leading: _deviceIcon(route.deviceType),
                            title: Text(route.deviceId),
                            subtitle: Text(route.deviceType.name),
                            trailing: route.active
                                ? const Icon(Icons.check_circle,
                                    color: Colors.green, size: 20)
                                : const Icon(Icons.radio_button_unchecked,
                                    size: 20),
                            onTap: () {
                              _svc.setRouteActive(app, route.deviceId);
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                FilledButton.icon(
                  onPressed: _addRoute,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Route'),
                ),
              ],
            ),
    );
  }

  List<String> _uniqueApps(RoutingMatrix matrix) {
    final seen = <String>{};
    return matrix.routes
        .where((r) => seen.add(r.appName))
        .map((r) => r.appName)
        .toList();
  }

  Widget _deviceIcon(AudioDeviceType type) {
    switch (type) {
      case AudioDeviceType.speaker:
        return const Icon(Icons.speaker);
      case AudioDeviceType.headphones:
        return const Icon(Icons.headphones);
      case AudioDeviceType.bluetooth:
        return const Icon(Icons.bluetooth);
      case AudioDeviceType.hdmi:
        return const Icon(Icons.tv);
      case AudioDeviceType.usb:
        return const Icon(Icons.usb);
      case AudioDeviceType.virtual:
        return const Icon(Icons.devices_other);
    }
  }

  void _addRoute() {
    final appCtrl = TextEditingController();
    final deviceCtrl = TextEditingController();
    var deviceType = AudioDeviceType.speaker;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Audio Route'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: appCtrl,
                decoration: const InputDecoration(labelText: 'App name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: deviceCtrl,
                decoration: const InputDecoration(labelText: 'Device ID'),
              ),
              const SizedBox(height: 8),
              DropdownButton<AudioDeviceType>(
                value: deviceType,
                isExpanded: true,
                items: AudioDeviceType.values
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => deviceType = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (appCtrl.text.isNotEmpty && deviceCtrl.text.isNotEmpty) {
                  _svc.addRoute(AudioRoute(
                    appName: appCtrl.text,
                    deviceId: deviceCtrl.text,
                    deviceType: deviceType,
                  ));
                }
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
