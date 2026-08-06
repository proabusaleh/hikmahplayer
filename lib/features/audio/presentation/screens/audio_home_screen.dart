import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../core/services/audio_service.dart';
import 'audio_routing_screen.dart';
import 'cast_screen.dart';
import 'equalizer_screen.dart';

class AudioHomeScreen extends StatefulWidget {
  const AudioHomeScreen({super.key});

  @override
  State<AudioHomeScreen> createState() => _AudioHomeScreenState();
}

class _AudioHomeScreenState extends State<AudioHomeScreen> {
  AudioService? _audio;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _audio ??= AppScope.of(context).audio;
  }

  AudioService get _svc => _audio!;

  @override
  Widget build(BuildContext context) {
    final running = _svc.status.values
        .where((s) => s == AudioAnalysisStatus.running)
        .length;
    final done = _svc.status.values
        .where((s) => s == AudioAnalysisStatus.done)
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('Audio')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (running > 0 || done > 0)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      running > 0 ? Icons.equalizer : Icons.check_circle_outline,
                      color: running > 0
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        running > 0
                            ? 'Analysing $running track(s)…'
                            : '$done track(s) analysed',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Text('Features', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _FeatureTile(
            icon: Icons.graphic_eq,
            title: 'Equaliser',
            subtitle: '10-band parametric EQ',
            onTap: () => Navigator.push(context,
                MaterialPageRoute<void>(builder: (_) => const EqualizerScreen())),
          ),
          _FeatureTile(
            icon: Icons.casino_outlined,
            title: 'Auto DJ',
            subtitle: 'BPM/key-aware smart mixing',
            onTap: () {},
          ),
          _FeatureTile(
            icon: Icons.cell_tower,
            title: 'Cast & Stream',
            subtitle: 'DLNA / AirPlay / Chromecast',
            onTap: () => Navigator.push(context,
                MaterialPageRoute<void>(builder: (_) => const CastScreen())),
          ),
          _FeatureTile(
            icon: Icons.bluetooth_audio,
            title: 'Bluetooth',
            subtitle: 'Codec & aptX config',
            onTap: () {},
          ),
          _FeatureTile(
            icon: Icons.spatial_audio_off,
            title: 'Spatial & Convolution',
            subtitle: 'HRTF / impulse responses',
            onTap: () {},
          ),
          _FeatureTile(
            icon: Icons.speed,
            title: 'Dynamics & Loudness',
            subtitle: 'Compression, limiter, LUFS',
            onTap: () {},
          ),
          _FeatureTile(
            icon: Icons.surround_sound,
            title: 'Crossfeed & Routing',
            subtitle: 'Stereo mix & channel matrix',
            onTap: () => Navigator.push(context,
                MaterialPageRoute<void>(builder: (_) => const AudioRoutingScreen())),
          ),
          _FeatureTile(
            icon: Icons.album,
            title: 'MQA / DSD / Bit-perfect',
            subtitle: 'Hi-res format passthrough',
            onTap: () {},
          ),
          _FeatureTile(
            icon: Icons.music_note,
            title: 'BPM / Key / Camelot',
            subtitle: 'Track analysis tools',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
