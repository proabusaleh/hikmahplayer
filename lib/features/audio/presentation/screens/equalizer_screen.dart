import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../core/services/audio_service.dart';
import '../../domain/models/equalizer.dart';

class EqualizerScreen extends StatefulWidget {
  const EqualizerScreen({super.key});

  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> {
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
    final eq = _svc.eq;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equaliser'),
        actions: [
          Switch(
            value: eq.enabled,
            onChanged: (v) {
              _svc.setEq(eq.copyWith(enabled: v));
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Preamp slider
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Preamp: ${eq.preampDb.toStringAsFixed(1)} dB',
                      style: Theme.of(context).textTheme.bodyMedium),
                  Slider(
                    value: eq.preampDb,
                    min: -20,
                    max: 20,
                    divisions: 80,
                    label: '${eq.preampDb.toStringAsFixed(1)} dB',
                    onChanged: eq.enabled
                        ? (v) => _svc.setEq(eq.copyWith(preampDb: v))
                        : null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Bands (${eq.bands.length})',
                  style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'Add band',
                onPressed: eq.bands.length < 20
                    ? () {
                        final bands = [
                          ...eq.bands,
                          const EqBand(frequencyHz: 1000),
                        ];
                        _svc.setEq(eq.copyWith(bands: bands));
                      }
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < eq.bands.length; i++)
            _BandCard(
              band: eq.bands[i],
              enabled: eq.enabled,
              onChanged: (b) {
                final bands = List<EqBand>.of(eq.bands);
                bands[i] = b;
                _svc.setEq(eq.copyWith(bands: bands));
              },
              onRemove: () {
                final bands = List<EqBand>.of(eq.bands)..removeAt(i);
                _svc.setEq(eq.copyWith(bands: bands));
              },
            ),
          if (eq.bands.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No EQ bands. Tap + to add one.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BandCard extends StatelessWidget {
  const _BandCard({
    required this.band,
    required this.enabled,
    required this.onChanged,
    required this.onRemove,
  });

  final EqBand band;
  final bool enabled;
  final ValueChanged<EqBand> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${band.frequencyHz.round()} Hz',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Text(
                  '${band.gainDb >= 0 ? '+' : ''}${band.gainDb.toStringAsFixed(1)} dB',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onRemove,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            Slider(
              value: band.gainDb,
              min: -20,
              max: 20,
              divisions: 80,
              onChanged: enabled ? (v) => onChanged(band.copyWith(gainDb: v)) : null,
            ),
            Row(
              children: [
                const Text('Q:', style: TextStyle(fontSize: 12)),
                Expanded(
                  child: Slider(
                    value: band.q,
                    min: 0.1,
                    max: 10,
                    divisions: 99,
                    label: band.q.toStringAsFixed(1),
                    onChanged: enabled
                        ? (v) => onChanged(band.copyWith(q: v))
                        : null,
                  ),
                ),
                Text(band.q.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
            Row(
              children: [
                const Text('Freq:', style: TextStyle(fontSize: 12)),
                Expanded(
                  child: Slider(
                    value: band.frequencyHz,
                    min: 20,
                    max: 20000,
                    divisions: 100,
                    onChanged: enabled
                        ? (v) => onChanged(band.copyWith(frequencyHz: v))
                        : null,
                  ),
                ),
                Text('${band.frequencyHz.round()} Hz',
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
