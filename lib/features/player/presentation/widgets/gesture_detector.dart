import 'package:flutter/material.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:volume_controller/volume_controller.dart';

import '../../../../core/services/playback_service.dart';
import '../providers/playback_provider.dart';

/// Full-screen gesture layer for the player.
///
/// * Single tap — toggle the controls
/// * Double tap left / right half — seek back / forward 10s
/// * Horizontal drag — scrub
/// * Vertical drag on the left half — screen brightness
/// * Vertical drag on the right half — volume
///
/// All platform channel calls (brightness / system volume) are guarded so the
/// widget is safe in tests and on unsupported platforms.
class PlayerGestureDetector extends StatelessWidget {
  const PlayerGestureDetector({
    super.key,
    required this.controller,
    required this.playback,
    required this.child,
  });

  final PlaybackController controller;
  final PlaybackService playback;
  final Widget child;

  static const double _seekStep = 10;

  Future<void> _setBrightness(double value) async {
    try {
      await ScreenBrightness().setScreenBrightness(value.clamp(0.0, 1.0));
    } catch (_) {}
  }

  Future<void> _setSystemVolume(double value) async {
    try {
      VolumeController().setVolume(value.clamp(0.0, 1.0), showSystemUI: false);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return _GestureArea(
      onTap: controller.toggleControls,
      onDoubleTapLeft: () {
        controller.seekBy(Duration(seconds: -_seekStep.toInt()));
        controller.showControls();
      },
      onDoubleTapRight: () {
        controller.seekBy(Duration(seconds: _seekStep.toInt()));
        controller.showControls();
      },
      onHorizontalDrag: (deltaFraction) {
        final duration = playback.duration.value;
        final target = playback.position.value +
            duration * deltaFraction;
        playback.seek(target < Duration.zero
            ? Duration.zero
            : (target > duration ? duration : target));
        controller.showGesture(
          '${controller.playback.position.value.inSeconds}s',
          0.5,
        );
        controller.showControls();
      },
      onVerticalDragLeft: (delta) {
        final next = (controller.gestureValue - delta).clamp(0.0, 1.0);
        controller.showGesture('Brightness', next);
        _setBrightness(next);
      },
      onVerticalDragRight: (delta) {
        final next = (controller.gestureValue - delta).clamp(0.0, 1.0);
        controller.showGesture('Volume', next);
        _setSystemVolume(next);
      },
      child: child,
    );
  }
}

class _GestureArea extends StatefulWidget {
  const _GestureArea({
    required this.onTap,
    required this.onDoubleTapLeft,
    required this.onDoubleTapRight,
    required this.onHorizontalDrag,
    required this.onVerticalDragLeft,
    required this.onVerticalDragRight,
    required this.child,
  });

  final VoidCallback onTap;
  final VoidCallback onDoubleTapLeft;
  final VoidCallback onDoubleTapRight;
  final ValueChanged<double> onHorizontalDrag; // delta fraction of total
  final ValueChanged<double> onVerticalDragLeft; // delta 0..1
  final ValueChanged<double> onVerticalDragRight; // delta 0..1
  final Widget child;

  @override
  State<_GestureArea> createState() => _GestureAreaState();
}

class _GestureAreaState extends State<_GestureArea> {
  double _lastDx = 0;
  double _lastDy = 0;
  bool _vertical = false;
  bool _horizontal = false;
  bool _left = false;

  void _onPanStart(DragStartDetails d, double width) {
    _lastDx = d.localPosition.dx;
    _lastDy = d.localPosition.dy;
    _left = d.localPosition.dx < width / 2;
    _vertical = false;
    _horizontal = false;
  }

  void _onPanUpdate(DragUpdateDetails d, double width) {
    final dx = d.localPosition.dx - _lastDx;
    final dy = d.localPosition.dy - _lastDy;
    _lastDx = d.localPosition.dx;
    _lastDy = d.localPosition.dy;

    if (!_vertical && !_horizontal) {
      if (dx.abs() > 2 || dy.abs() > 2) {
        if (dx.abs() > dy.abs()) {
          _horizontal = true;
        } else {
          _vertical = true;
        }
      } else {
        return;
      }
    }

    if (_horizontal) {
      widget.onHorizontalDrag(dx / width.clamp(1.0, double.infinity));
    } else if (_vertical) {
      final delta = dy / 600;
      if (_left) {
        widget.onVerticalDragLeft(delta);
      } else {
        widget.onVerticalDragRight(delta);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          onDoubleTapDown: (d) {
            _left = d.localPosition.dx < constraints.maxWidth / 2;
          },
          onDoubleTap: () {
            if (_left) {
              widget.onDoubleTapLeft();
            } else {
              widget.onDoubleTapRight();
            }
          },
          onPanStart: (d) => _onPanStart(d, constraints.maxWidth),
          onPanUpdate: (d) => _onPanUpdate(d, constraints.maxWidth),
          onPanEnd: (_) {
            _horizontal = false;
            _vertical = false;
          },
          onPanCancel: () {
            _horizontal = false;
            _vertical = false;
          },
          child: widget.child,
        );
      },
    );
  }
}
