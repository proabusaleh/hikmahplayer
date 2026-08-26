import 'package:flutter/material.dart';

import '../../../../core/services/playback_service.dart';
import '../../../../shared/utils/format.dart';
import '../../domain/models/chapter.dart';

/// Draggable seek bar with buffered region, chapter markers and elapsed/total
/// time labels.
///
/// Dragging produces a continuous preview value through [onPreview] (used by
/// the timeline preview / smart scrubber) and commits on release through
/// [onCommit].
class PlayerSeekBar extends StatelessWidget {
  const PlayerSeekBar({
    super.key,
    required this.playback,
    this.onPreview,
    this.onCommit,
    this.height = 44,
  });

  final PlaybackService playback;
  final ValueChanged<Duration>? onPreview;
  final ValueChanged<Duration>? onCommit;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<Duration>(
      valueListenable: playback.position,
      builder: (context, position, _) {
        final duration = playback.duration.value;
        final buffered = playback.buffered.value;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Track(
              height: height - 16,
              position: position,
              duration: duration,
              buffered: buffered,
              chapters: playback.currentItem?.chapters ?? const [],
              onPreview: onPreview,
              onCommit: onCommit,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    Fmt.duration(position),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white70,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    Fmt.duration(duration),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white38,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Track extends StatefulWidget {
  const _Track({
    required this.height,
    required this.position,
    required this.duration,
    required this.buffered,
    required this.chapters,
    this.onPreview,
    this.onCommit,
  });

  final double height;
  final Duration position;
  final Duration duration;
  final Duration buffered;
  final List<Chapter> chapters;
  final ValueChanged<Duration>? onPreview;
  final ValueChanged<Duration>? onCommit;

  @override
  State<_Track> createState() => _TrackState();
}

class _TrackState extends State<_Track> {
  bool _dragging = false;
  double _dragFraction = 0.0;

  double get _fraction {
    if (_dragging) return _dragFraction;
    if (widget.duration == Duration.zero) return 0;
    return (widget.position.inMilliseconds / widget.duration.inMilliseconds)
        .clamp(0.0, 1.0);
  }

  Duration _durationFor(double fraction) {
    return widget.duration * fraction.clamp(0.0, 1.0);
  }

  void _onPanStart(DragStartDetails details, double width) {
    if (width <= 0) return;
    _dragging = true;
    _dragFraction = (details.localPosition.dx / width).clamp(0.0, 1.0);
    widget.onPreview?.call(_durationFor(_dragFraction));
    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails details, double width) {
    if (width <= 0) return;
    _dragFraction = (details.localPosition.dx / width).clamp(0.0, 1.0);
    widget.onPreview?.call(_durationFor(_dragFraction));
    setState(() {});
  }

  void _onPanEnd(double width) {
    if (!_dragging) return;
    _dragging = false;
    widget.onCommit?.call(_durationFor(_dragFraction));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) {
            final fraction = (d.localPosition.dx / width).clamp(0.0, 1.0);
            widget.onCommit?.call(_durationFor(fraction));
          },
          onPanStart: (d) => _onPanStart(d, width),
          onPanUpdate: (d) => _onPanUpdate(d, width),
          onPanEnd: (_) => _onPanEnd(width),
          onPanCancel: () {
            _dragging = false;
            setState(() {});
          },
          child: SizedBox(
            height: widget.height,
            child: CustomPaint(
              painter: _SeekTrackPainter(
                fraction: _fraction,
                bufferedFraction: widget.duration == Duration.zero
                    ? 0
                    : (widget.buffered.inMilliseconds /
                            widget.duration.inMilliseconds)
                        .clamp(0.0, 1.0),
                chapterFractions: widget.duration == Duration.zero
                    ? const []
                    : [
                        for (final c in widget.chapters)
                          (c.start.inMilliseconds /
                                  widget.duration.inMilliseconds)
                              .clamp(0.0, 1.0),
                      ],
                activeColor: scheme.primary,
                bufferColor: scheme.primary.withValues(alpha: 0.35),
                trackColor: Colors.white.withValues(alpha: 0.15),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SeekTrackPainter extends CustomPainter {
  const _SeekTrackPainter({
    required this.fraction,
    required this.bufferedFraction,
    required this.chapterFractions,
    required this.activeColor,
    required this.bufferColor,
    required this.trackColor,
  });

  final double fraction;
  final double bufferedFraction;
  final List<double> chapterFractions;
  final Color activeColor;
  final Color bufferColor;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.height / 2;
    const radius = 3.0;
    final track = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, center - radius, size.width, radius * 2),
      const Radius.circular(3.0),
    );
    canvas.drawRRect(track, Paint()..color = trackColor);

    if (bufferedFraction > 0.01) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
              0, center - radius, size.width * bufferedFraction, radius * 2),
          const Radius.circular(3.0),
        ),
        Paint()..color = bufferColor,
      );
    }

    for (final c in chapterFractions) {
      final dx = size.width * c;
      canvas.drawLine(
        Offset(dx, center - 8),
        Offset(dx, center + 8),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.85)
          ..strokeWidth = 1.5,
      );
    }

    if (fraction > 0.01) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, center - radius, size.width * fraction, radius * 2),
          const Radius.circular(3.0),
        ),
        Paint()..color = activeColor,
      );
    }

    final thumbX = (size.width * fraction).clamp(0.0, size.width);
    canvas.drawCircle(
      Offset(thumbX, center),
      7,
      Paint()..color = activeColor,
    );
    canvas.drawCircle(
      Offset(thumbX, center),
      3.5,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_SeekTrackPainter oldDelegate) =>
      oldDelegate.fraction != fraction ||
      oldDelegate.bufferedFraction != bufferedFraction ||
      oldDelegate.chapterFractions != chapterFractions;
}
