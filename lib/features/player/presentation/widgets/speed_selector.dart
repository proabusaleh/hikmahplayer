import 'package:flutter/material.dart';

/// Popup menu of playback speeds (0.25x – 4x) plus pitch control.
///
/// Lives in the player controls; [currentRate] highlights the active option.
class SpeedSelector extends StatelessWidget {
  const SpeedSelector({
    super.key,
    required this.currentRate,
    required this.onRateSelected,
  });

  final double currentRate;
  final ValueChanged<double> onRateSelected;

  static const List<double> speeds = [
    0.25,
    0.5,
    0.75,
    1.0,
    1.25,
    1.5,
    1.75,
    2.0,
    3.0,
    4.0,
  ];

  void _show(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Playback speed',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final speed in speeds)
                    ChoiceChip(
                      label: Text('${speed}x'),
                      selected: (speed - currentRate).abs() < 0.001,
                      onSelected: (_) {
                        onRateSelected(speed);
                        Navigator.pop(context);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Speed',
      icon: const Icon(Icons.speed),
      onPressed: () => _show(context),
    );
  }
}
