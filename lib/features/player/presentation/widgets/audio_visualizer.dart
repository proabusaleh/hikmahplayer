import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/services/playback_service.dart';

/// Animated spectrum-style bars used as the backdrop for audio-only playback.
///
/// Bars pulse when the media is playing and settle when paused.
class AudioVisualizer extends StatefulWidget {
  const AudioVisualizer({
    super.key,
    required this.playback,
    this.barCount = 48,
    this.color,
  });

  final PlaybackService playback;
  final int barCount;
  final Color? color;

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void initState() {
    super.initState();
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.playback.isPlaying,
      builder: (context, isPlaying, _) {
        _controller.repeat();
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _BarPainter(
                time: _controller.value,
                playing: isPlaying,
                barCount: widget.barCount,
                color: widget.color ?? Theme.of(context).colorScheme.primary,
              ),
              size: Size.infinite,
            );
          },
        );
      },
    );
  }
}

class _BarPainter extends CustomPainter {
  const _BarPainter({
    required this.time,
    required this.playing,
    required this.barCount,
    required this.color,
  });

  final double time;
  final bool playing;
  final int barCount;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..strokeCap = StrokeCap.round;
    final gap = size.width / (barCount * 2.5);
    final barWidth = gap * 0.8;
    final maxHeight = size.height * 0.55;

    for (var i = 0; i < barCount; i++) {
      final phase = (i / barCount) * math.pi * 4;
      final wave = math.sin(phase + time * math.pi * 4);
      final idle = 0.15 + 0.05 * math.sin(phase * 0.7);
      final value = playing ? (wave.abs() * 0.85 + 0.15) : idle;
      final barHeight = maxHeight * value.clamp(0.05, 1.0);
      final x = gap * (i * 2.5 + 1);
      final y = (size.height - barHeight) / 2;
      canvas.drawLine(
        Offset(x, y),
        Offset(x, y + barHeight),
        paint..strokeWidth = barWidth,
      );
    }
  }

  @override
  bool shouldRepaint(_BarPainter oldDelegate) =>
      oldDelegate.time != time ||
      oldDelegate.playing != playing ||
      oldDelegate.color != color;
}
