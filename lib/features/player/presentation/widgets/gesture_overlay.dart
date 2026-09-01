import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:volume_controller/volume_controller.dart';

import '../../../../core/extensions/duration_extensions.dart';
import '../providers/player_state_provider.dart';

class GestureOverlay extends ConsumerStatefulWidget {
  final VoidCallback onInteraction;

  const GestureOverlay({super.key, required this.onInteraction});

  @override
  ConsumerState<GestureOverlay> createState() => _GestureOverlayState();
}

class _GestureOverlayState extends ConsumerState<GestureOverlay> {
  // Indicators
  double? _brightnessValue;
  double? _volumeValue;
  Duration? _seekPreview;

  Timer? _indicatorTimer;

  double _startY = 0;
  double _startX = 0;
  double _startBrightness = 0.5;
  double _startVolume = 0.5;
  Duration _startPosition = Duration.zero;

  bool _isVerticalDrag = false;
  bool _isLeftSide = false;

  @override
  void initState() {
    super.initState();
    _initValues();
  }

  Future<void> _initValues() async {
    try {
      _startBrightness = await ScreenBrightness().current;
      _startVolume = await VolumeController().getVolume();
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

  void _onVerticalDragStart(DragStartDetails details) async {
    _startY = details.globalPosition.dy;
    _isVerticalDrag = true;

    final screenWidth = MediaQuery.of(context).size.width;
    _isLeftSide = details.globalPosition.dx < screenWidth / 2;

    if (_isLeftSide) {
      _startBrightness = await ScreenBrightness().current;
    } else {
      _startVolume = await VolumeController().getVolume();
    }
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) async {
    if (!_isVerticalDrag) return;

    widget.onInteraction();

    final screenHeight = MediaQuery.of(context).size.height;
    final deltaY = _startY - details.globalPosition.dy;
    final delta = deltaY / (screenHeight * 0.5); // Full swipe = 100%

    if (_isLeftSide) {
      // BRIGHTNESS (left side)
      final newBrightness = (_startBrightness + delta).clamp(0.0, 1.0);
      try {
        await ScreenBrightness().setScreenBrightness(newBrightness);
        setState(() => _brightnessValue = newBrightness);
      } catch (_) {}
    } else {
      // VOLUME (right side)
      final newVolume = (_startVolume + delta).clamp(0.0, 1.0);
      try {
        VolumeController().setVolume(newVolume, showSystemUI: false);
        setState(() => _volumeValue = newVolume);
      } catch (_) {}
    }
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    _startX = details.globalPosition.dx;
    _isVerticalDrag = false;
    _startPosition = ref.read(playerStateProvider).position;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_isVerticalDrag) return;

    widget.onInteraction();

    final screenWidth = MediaQuery.of(context).size.width;
    final deltaX = details.globalPosition.dx - _startX;
    final duration = ref.read(playerStateProvider).duration;

    // 1 full swipe = 90 seconds
    final seekDelta = Duration(
      seconds: ((deltaX / screenWidth) * 90).round(),
    );

    var newPos = _startPosition + seekDelta;
    if (newPos < Duration.zero) newPos = Duration.zero;
    if (newPos > duration) newPos = duration;

    setState(() => _seekPreview = newPos);
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_seekPreview != null) {
      ref.read(playerStateProvider.notifier).seekTo(_seekPreview!);
    }
    _showIndicator();
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    _showIndicator();
  }

  void _onDoubleTapDown(TapDownDetails details) {
    widget.onInteraction();

    final screenWidth = MediaQuery.of(context).size.width;
    final isLeftSide = details.globalPosition.dx < screenWidth / 2;

    final controller = ref.read(playerStateProvider.notifier);
    if (isLeftSide) {
      controller.seekBackward();
    } else {
      controller.seekForward();
    }
  }

  @override
  void dispose() {
    _indicatorTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ─── Gesture Detection ───
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onDoubleTapDown: _onDoubleTapDown,
            onDoubleTap: () {}, // Required for onDoubleTapDown
            onVerticalDragStart: _onVerticalDragStart,
            onVerticalDragUpdate: _onVerticalDragUpdate,
            onVerticalDragEnd: _onVerticalDragEnd,
            onHorizontalDragStart: _onHorizontalDragStart,
            onHorizontalDragUpdate: _onHorizontalDragUpdate,
            onHorizontalDragEnd: _onHorizontalDragEnd,
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
            icon: _volumeValue! == 0
                ? Icons.volume_off
                : (_volumeValue! < 0.5 ? Icons.volume_down : Icons.volume_up),
            value: _volumeValue!,
            label: 'Volume',
          ),

        // ─── Seek Preview ───
        if (_seekPreview != null)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
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
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.white),
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
