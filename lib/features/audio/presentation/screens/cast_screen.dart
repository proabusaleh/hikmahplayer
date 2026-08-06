import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../core/services/audio_service.dart';
import '../../domain/models/cast.dart';

class CastScreen extends StatefulWidget {
  const CastScreen({super.key});

  @override
  State<CastScreen> createState() => _CastScreenState();
}

class _CastScreenState extends State<CastScreen> {
  AudioService? _audio;
  bool _scanning = false;
  List<CastDevice> _discovered = [];

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
    final settings = _svc.cast;
    final activeSession = _svc.activeCastSession();

    return Scaffold(
      appBar: AppBar(title: const Text('Cast & Stream')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (activeSession != null) ...[
            _ActiveSessionCard(
              session: activeSession,
              onDisconnect: () => _svc.disconnectCast(activeSession.device.id),
              onToggleLossless: () {
                _svc.updateCastSession(
                  activeSession.device.id,
                  activeSession.copyWith(
                    bitPerfectLossless: !activeSession.bitPerfectLossless,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
          Text('Settings', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Lossless preferred'),
                  subtitle: const Text('Use lossless codecs when available'),
                  value: settings.losslessPreferred,
                  onChanged: (v) =>
                      _svc.setCast(settings.copyWith(losslessPreferred: v)),
                ),
                ListTile(
                  title: const Text('Buffer size'),
                  subtitle: Text('${settings.bufferSeconds} seconds'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _adjustBuffer(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Protocols', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final protocol in CastProtocol.values)
            Card(
              child: ListTile(
                leading: Icon(_protocolIcon(protocol)),
                title: Text(protocol.name.toUpperCase()),
                subtitle: Text(_protocolDescription(protocol)),
              ),
            ),
          const SizedBox(height: 16),
          Text('Discovered Devices', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_scanning)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Scanning for devices…'),
                  ],
                ),
              ),
            )
          else if (_discovered.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('No devices found'),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _scanDevices,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Scan again'),
                    ),
                  ],
                ),
              ),
            )
          else
            for (final device in _discovered)
              Card(
                child: ListTile(
                  leading: Icon(_protocolIcon(device.protocol)),
                  title: Text(device.name),
                  subtitle: Text(
                    '${device.protocol.name}'
                    '${device.lossless ? ' · Lossless' : ''}',
                  ),
                  trailing: FilledButton.tonal(
                    onPressed: () => _connect(device),
                    child: const Text('Connect'),
                  ),
                ),
              ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _scanning ? null : _scanDevices,
            icon: const Icon(Icons.wifi_find),
            label: const Text('Scan for Devices'),
          ),
        ],
      ),
    );
  }

  Future<void> _scanDevices() async {
    setState(() => _scanning = true);
    final devices = await _svc.discoverCastDevices();
    if (mounted) {
      setState(() {
        _scanning = false;
        _discovered = devices;
      });
    }
  }

  Future<void> _connect(CastDevice device) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Connecting to ${device.name}…')),
    );
    final session = await _svc.connectToCast(device);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected to ${session.device.name}')),
      );
    }
  }

  void _adjustBuffer() {
    final current = _svc.cast.bufferSeconds;
    showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Buffer Size'),
        children: [1, 2, 3, 5, 8, 10].map((s) {
          return SimpleDialogOption(
            onPressed: () {
              _svc.setCast(_svc.cast.copyWith(bufferSeconds: s));
              Navigator.pop(context);
            },
            child: Row(
              children: [
                if (s == current) const Icon(Icons.check, size: 18),
                if (s == current) const SizedBox(width: 8),
                Text('$s seconds'),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _protocolIcon(CastProtocol protocol) {
    switch (protocol) {
      case CastProtocol.upnp:
        return Icons.wifi;
      case CastProtocol.chromecast:
        return Icons.cast;
      case CastProtocol.airplay2:
        return Icons.air;
      case CastProtocol.sonos:
        return Icons.surround_sound;
      case CastProtocol.bluetooth:
        return Icons.bluetooth;
    }
  }

  String _protocolDescription(CastProtocol protocol) {
    switch (protocol) {
      case CastProtocol.upnp:
        return 'UPnP/DLNA with lossless streaming';
      case CastProtocol.chromecast:
        return 'Google Chromecast built-in';
      case CastProtocol.airplay2:
        return 'Apple AirPlay 2 multi-room';
      case CastProtocol.sonos:
        return 'Sonos ecosystem integration';
      case CastProtocol.bluetooth:
        return 'SBC, AAC, aptX HD, LDAC codecs';
    }
  }
}

class _ActiveSessionCard extends StatelessWidget {
  const _ActiveSessionCard({
    required this.session,
    required this.onDisconnect,
    required this.onToggleLossless,
  });

  final CastSession session;
  final VoidCallback onDisconnect;
  final VoidCallback onToggleLossless;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  session.state == CastSessionState.streaming
                      ? Icons.cast_connected
                      : Icons.cast,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    session.device.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  session.state.name,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${session.device.protocol.name}'
              '${session.bitPerfectLossless ? ' · Bit-perfect lossless' : ''}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton.tonal(
                  onPressed: onToggleLossless,
                  child: Text(
                    session.bitPerfectLossless ? 'Lossless ON' : 'Lossless OFF',
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: onDisconnect,
                  child: const Text('Disconnect'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
