import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:volume_controller/volume_controller.dart';

import '../../../../core/di/app_scope.dart';
import '../../../../core/extensions/duration_extensions.dart';
import '../providers/player_state_provider.dart';

/// Full-screen gesture layer for the enhanced video player.
///
/// * Left-vertical drag → brightness, right-vertical drag → volume
/// * Horizontal drag → elapsed seek (with live time preview)
/// * Double-tap left/right → seek by the configured step
/// * Long-press → temporary 2× speed boost while pressed
/// * Two-finger pinch → zoom; when zoomed, one-finger drags pan instead
class GestureOverlay extends ConsumerStatefulWidget {
  final VoidCallback onInteraction;
  final bool locked;
  final TransformationController? transformController;
  final void Function(Duration)? onSeekEnd;

  const GestureOverlay({
    super.key,
    required this.onInteraction,
    this.locked = false,
    this.transformController,
    this.onSeekEnd,
  });

  @override
  ConsumerState<GestureOverlay> createState() => _GestureOverlayState();
}

class _GestureOverlayState extends ConsumerState<GestureOverlay> {
  // Indicators
  double? _brightnessValue;
  double? _volumeValue;
  Duration? _seekPreview;
  bool _boostActive = false;

  Timer? _indicatorTimer;

  double _startY = 0;
  double _startX = 0;
  double _startBrightness = 0.5;
  double _startVolume = 0.5;
  Duration _startPosition = Duration.zero;
  bool _isVerticalDrag = false;
  bool _isLeftSide = false;

  // Zoom / pan
  double _startZoom = 1.0;
  Offset _startPan = Offset.zero;
  Offset _focalPoint = Offset.zero;
  bool _isScaling = false;

  double get _currentZoom {
    final matrix = widget.transformController?.value;
    if (matrix == null) return 1.0;
    final scale = matrix.getMaxScaleOnAxis();
    return scale > 0 ? scale : 1.0;
  }

  bool get _isZoomed => widget.transformController != null && _currentZoom > 1.02;

  @override
  void initState() {
    super.initState();
    _initValues();
  }

  Future<void> _initValues() async {
    try {
      _startBrightness = await ScreenBrightness().application;
      _startVolume = await VolumeController.instance.getVolume();
    } catch (_) {}
  }

  void _showIndicator() {
    _indicatorTimer?.cancel();
    _indicatorTimer = Timer(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _brightnessValue = null;
          _volumeValue = null;
          _seekPreview = null;
        });
      }
    });
  }

  // ─── Zoom / pan helpers ───

  void _applyZoom(double zoom, Offset pan) {
    final matrix = Matrix4.diagonal3Values(zoom, zoom, 1)
      ..setTranslationRaw(pan.dx, pan.dy, 0);
    widget.transformController?.value = matrix;
  }

  void _resetZoom() {
    if (_currentZoom <= 1.05) return;
    setState(() {});
    _applyZoom(1.0, Offset.zero);
  }

  // ─── Long-press 2× boost ───

  Future<void> _onLongPressStart(LongPressStartDetails details) async {
    if (_isZoomed) return;
    widget.onInteraction();
    final notifier = ref.read(playerStateProvider.notifier);
    _startBoost = ref.read(playerStateProvider).speed;
    await notifier.setSpeed(2.0);
    if (mounted) setState(() => _boostActive = true);
  }

  late double _startBoost;

  Future<void> _onLongPressEnd(LongPressEndDetails details) async {
    if (_boostActive) {
      await ref.read(playerStateProvider.notifier).setSpeed(_startBoost);
      if (mounted) setState(() => _boostActive = false);
    }
  }

  // ─── Vertical (brightness / volume / pan) ───

  void _onVerticalDragStart(DragStartDetails details) {
    _startY = details.globalPosition.dy;
    _isVerticalDrag = true;
    _startPan = _panFromController();

    final screenWidth = MediaQuery.of(context).size.width;
    _isLeftSide = details.globalPosition.dx < screenWidth / 2;
  }

  Offset _panFromController() {
    final matrix = widget.transformController?.value;
    if (matrix == null) return Offset.zero;
    final translation = matrix.getTranslation();
    return Offset(translation.x, translation.y);
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (!_isVerticalDrag) return;

    widget.onInteraction();

    if (_isZoomed) {
      // Pan vertically while zoomed.
      final newPan = _startPan + Offset(0, details.delta.dy);
      _applyZoom(_currentZoom, newPan);
      return;
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final deltaY = _startY - details.globalPosition.dy;
    final delta = deltaY / (screenHeight * 0.5); // Full swipe = 100%

    if (_isLeftSide) {
      // BRIGHTNESS (left side)
      final newBrightness = (_startBrightness + delta).clamp(0.0, 1.0);
      try {
        ScreenBrightness().setApplicationScreenBrightness(newBrightness);
        setState(() => _brightnessValue = newBrightness);
      } catch (_) {}
    } else {
      // VOLUME (right side)
      final newVolume = (_startVolume + delta).clamp(0.0, 1.0);
      try {
        VolumeController.instance.showSystemUI = false;
        VolumeController.instance.setVolume(newVolume);
        setState(() => _volumeValue = newVolume);
      } catch (_) {}
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    _showIndicator();
  }

  // ─── Horizontal (seek / pan) ───

  void _onHorizontalDragStart(DragStartDetails details) {
    _startX = details.globalPosition.dx;
    _isVerticalDrag = false;
    _startPan = _panFromController();
    _startPosition = ref.read(playerStateProvider).position;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_isVerticalDrag) return;

    widget.onInteraction();

    if (_isZoomed) {
      // Pan horizontally while zoomed.
      final newPan = _startPan + Offset(details.delta.dx, 0);
      _applyZoom(_currentZoom, newPan);
      return;
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final deltaX = details.globalPosition.dx - _startX;
    final duration = ref.read(playerStateProvider).duration;

    // 1 full swipe = 90 seconds
    final seekDelta = Duration(seconds: ((deltaX / screenWidth) * 90).round());

    var newPos = _startPosition + seekDelta;
    if (newPos < Duration.zero) newPos = Duration.zero;
    if (newPos > duration) newPos = duration;

    setState(() => _seekPreview = newPos);
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_seekPreview != null) {
      ref.read(playerStateProvider.notifier).seekTo(_seekPreview!);
      widget.onSeekEnd?.call(_seekPreview!);
    }
    _showIndicator();
  }

  // ─── Pinch zoom ───

  void _onScaleStart(ScaleStartDetails details) {
    final controller = widget.transformController;
    if (controller == null) return;
    _startZoom = _currentZoom;
    _startPan = _panFromController();
    _focalPoint = details.localFocalPoint;
    _isScaling = true;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final controller = widget.transformController;
    if (controller == null || !_isScaling) return;
    widget.onInteraction();

    final newZoom = (_startZoom * details.scale).clamp(1.0, 5.0);
    final focalDelta = details.localFocalPoint - _focalPoint;
    final newPan = _startPan + focalDelta;
    setState(() {});
    _applyZoom(newZoom, newPan);
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _isScaling = false;
  }

  // ─── Double-tap seek ───

  void _onDoubleTapDown(TapDownDetails details) {
    if (_isZoomed) {
      _resetZoom();
      return;
    }
    widget.onInteraction();

    final screenWidth = MediaQuery.of(context).size.width;
    final isLeftSide = details.globalPosition.dx < screenWidth / 2;
    final step = Duration(
      seconds: AppScope.of(context).prefs.seekStepSeconds,
    );

    final controller = ref.read(playerStateProvider.notifier);
    if (isLeftSide) {
      controller.seekBackward(step);
    } else {
      controller.seekForward(step);
    }
  }

  @override
  void dispose() {
    _indicatorTimer?.cancel();
    if (_boostActive) {
      _boostActive = false;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.locked) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        // ─── Gesture Detection ───
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onDoubleTapDown: _onDoubleTapDown,
            onDoubleTap: () {}, // Required for onDoubleTapDown
            onLongPressStart: _onLongPressStart,
            onLongPressEnd: _onLongPressEnd,
            onVerticalDragStart: _onVerticalDragStart,
            onVerticalDragUpdate: _onVerticalDragUpdate,
            onVerticalDragEnd: _onVerticalDragEnd,
            onHorizontalDragStart: _onHorizontalDragStart,
            onHorizontalDragUpdate: _onHorizontalDragUpdate,
            onHorizontalDragEnd: _onHorizontalDragEnd,
            onScaleStart: _onScaleStart,
            onScaleUpdate: _onScaleUpdate,
            onScaleEnd: _onScaleEnd,
          ),
        ),

        // ─── Brightness Indicator ───
        if (_brightnessValue != null)
          _CenterIndicator(
            icon: Icons.brightness_6,
            value: _brightnessValue!,
            label: 'Brightness',
          ),

        // ─── Volume Indicator ───
        if (_volumeValue != null)
          _CenterIndicator(
            icon:
                _volumeValue! == 0
                    ? Icons.volume_off
                    : (_volumeValue! < 0.5
                        ? Icons.volume_down
                        : Icons.volume_up),
            value: _volumeValue!,
            label: 'Volume',
          ),

        // ─── Seek Preview ───
        if (_seekPreview != null)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _seekPreview!.formatted,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
          ),

        // ─── 2× Boost Indicator ───
        if (_boostActive)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.speed, color: Colors.white, size: 40),
                  SizedBox(height: 8),
                  Text(
                    '2× Turbo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // ─── Zoom Indicator ───
        if (_isZoomed)
          Positioned(
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${(_currentZoom).toStringAsFixed(1)}× zoom · double-tap to reset',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }
}

class _CenterIndicator extends StatelessWidget {
  final IconData icon;
  final double value; // 0.0 - 1.0
  final String label;

  const _CenterIndicator({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 48),
            const SizedBox(height: 12),
            SizedBox(
              width: 120,
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(value * 100).round()}%',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}