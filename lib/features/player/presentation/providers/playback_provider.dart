import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/services/playback_service.dart';
import '../../../../core/services/subtitle_service.dart';
import '../../domain/models/bookmark.dart';
import '../../domain/models/media_item.dart';
import '../../domain/models/playback_queue.dart';

/// Transient UI state + convenience actions for the full-screen player.
///
/// The [PlaybackService] already exposes hot playback state; this controller
/// layers on top the view-level state the player owns: control visibility,
/// drag gestures, A-B repeat, the sleep timer and in-memory bookmarks.
class PlaybackController extends ChangeNotifier {
  PlaybackController(this._playback, this._subtitleService) {
    _positionListener = () {
      _maybeLoop();
      _maybeNotify();
    };
    _playback.position.addListener(_positionListener!);
  }

  final PlaybackService _playback;
  final SubtitleService _subtitleService;
  VoidCallback? _positionListener;

  // ---------------------------------------------------------------------
  // Control visibility
  // ---------------------------------------------------------------------

  bool controlsVisible = true;
  Timer? _hideTimer;

  void showControls({bool autoHide = true}) {
    controlsVisible = true;
    _hideTimer?.cancel();
    if (autoHide) {
      _hideTimer = Timer(const Duration(seconds: 3), () {
        controlsVisible = false;
        notifyListeners();
      });
    }
    notifyListeners();
  }

  void toggleControls() {
    if (controlsVisible) {
      _hideTimer?.cancel();
      controlsVisible = false;
    } else {
      showControls();
    }
    notifyListeners();
  }

  void hideControls() {
    _hideTimer?.cancel();
    controlsVisible = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Gesture feedback overlay
  // ---------------------------------------------------------------------

  bool gestureActive = false;
  String gestureLabel = '';
  double gestureValue = 0.0; // 0..1 for the value track
  Timer? _gestureClearTimer;

  void showGesture(String label, double value) {
    gestureActive = true;
    gestureLabel = label;
    gestureValue = value.clamp(0.0, 1.0);
    _gestureClearTimer?.cancel();
    _gestureClearTimer = Timer(const Duration(milliseconds: 700), () {
      gestureActive = false;
      notifyListeners();
    });
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Opening content
  // ---------------------------------------------------------------------

  Future<void> openItem(MediaItem item, {bool autoplay = true}) async {
    await _playback.openItem(item, autoplay: autoplay);
    await _attachSubtitles(item);
    notifyListeners();
  }

  Future<void> openQueue(PlaybackQueue queue, {bool autoplay = true}) async {
    await _playback.openQueue(queue, autoplay: autoplay);
    final current = queue.current;
    if (current != null) await _attachSubtitles(current);
    notifyListeners();
  }

  Future<void> _attachSubtitles(MediaItem item) async {
    // Try already-attached parsed subtitles first (from the subtitle service),
    // then look for sidecar files next to the media.
    final existing = _subtitleService.subtitleFor(item.id);
    if (existing != null) {
      await _playback.setExternalSubtitles(
        existing.segments.isEmpty ? '' : '',
        title: item.title,
      );
      return;
    }
    if (item.uri.startsWith('file:///') || item.uri.startsWith('file://')) {
      final path = item.uri.replaceFirst(RegExp(r'^file:///'), '').replaceFirst(RegExp(r'^file://'), '');
      final dir = path.contains('\\')
          ? path.substring(0, path.lastIndexOf('\\'))
          : path.substring(0, path.lastIndexOf('/'));
      final base = path.contains('\\')
          ? path.substring(path.lastIndexOf('\\') + 1)
          : path.substring(path.lastIndexOf('/') + 1);
      final name = base.contains('.')
          ? base.substring(0, base.lastIndexOf('.'))
          : base;
      final sidecars = _subtitleService.findSidecars(dir, name);
      if (sidecars.isNotEmpty) {
        final parsed = await _subtitleService.loadFromFile(sidecars.first, mediaId: item.id);
        if (parsed != null && !parsed.isEmpty) {
          await _playback.setExternalSubtitles(
            sidecars.first.path,
            title: sidecars.first.path.split(RegExp(r'[\\/]')).last,
          );
        }
      }
    }
  }

  // ---------------------------------------------------------------------
  // A-B repeat loop
  // ---------------------------------------------------------------------

  Duration? aPoint;
  Duration? bPoint;

  void setAPoint(Duration position) {
    aPoint = position;
    bPoint = null;
    notifyListeners();
  }

  void setBPoint(Duration position) {
    bPoint = position;
    notifyListeners();
  }

  void clearLoop() {
    aPoint = null;
    bPoint = null;
    notifyListeners();
  }

  bool get loopActive => aPoint != null && bPoint != null;

  void _maybeLoop() {
    final a = aPoint;
    final b = bPoint;
    if (a == null || b == null) return;
    if (b <= a) return;
    final position = _playback.position.value;
    if (position >= b) {
      _playback.seek(a);
      _playback.play();
    }
  }

  // ---------------------------------------------------------------------
  // Sleep timer
  // ---------------------------------------------------------------------

  Duration? sleepRemaining;
  Timer? _sleepTimer;

  /// Sets a sleep timer that pauses playback when [delay] elapses.
  void setSleepTimer(Duration? delay) {
    _sleepTimer?.cancel();
    if (delay == null) {
      sleepRemaining = null;
      notifyListeners();
      return;
    }
    sleepRemaining = delay;
    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final current = sleepRemaining;
      if (current == null) {
        _sleepTimer?.cancel();
        return;
      }
      final next = current - const Duration(seconds: 1);
      if (next <= Duration.zero) {
        sleepRemaining = null;
        _sleepTimer?.cancel();
        _playback.pause();
        notifyListeners();
      } else {
        sleepRemaining = next;
        notifyListeners();
      }
    });
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Bookmarks
  // ---------------------------------------------------------------------

  final List<Bookmark> _bookmarks = [];

  List<Bookmark> get bookmarks => List.unmodifiable(_bookmarks);

  Bookmark addBookmark(String label, {String? note}) {
    final mediaId = _playback.currentMediaId.value;
    final position = _playback.position.value;
    final bookmark = Bookmark(
      id: 'bm-${DateTime.now().microsecondsSinceEpoch}',
      mediaId: mediaId ?? 'unknown',
      position: position,
      label: label,
      note: note,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _bookmarks.add(bookmark);
    notifyListeners();
    return bookmark;
  }

  void removeBookmark(String id) {
    _bookmarks.removeWhere((b) => b.id == id);
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Shortcuts
  // ---------------------------------------------------------------------

  PlaybackService get playback => _playback;

  Future<void> seekToFraction(double fraction) =>
      _playback.seekToFraction(fraction);

  Future<void> seekBy(Duration offset) => _playback.seekBy(offset);

  Future<void> togglePlay() => _playback.playPause();

  Future<void> setRate(double rate) => _playback.setRate(rate);

  bool _notified = false;

  void _maybeNotify() {
    // Throttle notifyListeners while the position stream is hot.
    if (_notified) return;
    _notified = true;
    scheduleMicrotask(() {
      _notified = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _gestureClearTimer?.cancel();
    _sleepTimer?.cancel();
    if (_positionListener != null) {
      _playback.position.removeListener(_positionListener!);
    }
    super.dispose();
  }
}
