import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/playback_service.dart';
import '../../../../core/services/subtitle_service.dart';
import '../../../../core/storage/prefs_service.dart';
import '../../../../core/storage/repositories/history_repository.dart';
import '../../../../core/storage/repositories/media_repository.dart'
    hide MediaItem;
import '../../../../core/storage/repositories/player_data_repository.dart';
import '../../domain/models/bookmark.dart';
import '../../domain/models/media_item.dart';
import '../../domain/models/playback_queue.dart';
import '../../domain/models/player_note.dart';
import '../../domain/models/user_chapter.dart';

/// How a sleep timer ends playback.
enum SleepMode {
  /// Playback pauses after a fixed countdown.
  timer,

  /// Playback pauses when the current item reaches its end.
  endOfMedia,

  /// Playback pauses when the last item of the queue finishes.
  endOfQueue,
}

/// Recorded playback sessions for the local, privacy-friendly analytics.
const Uuid _sessionUuid = Uuid();

/// Transient UI state + convenience actions for the full-screen player.
///
/// The [PlaybackService] already exposes hot playback state; this controller
/// layers on top the view-level state the player owns: control visibility,
/// drag gestures, A-B repeat, the sleep timer and player-anchored data
/// (bookmarks, notes, user chapters) persisted through [PlayerDataRepository].
class PlaybackController extends ChangeNotifier {
  PlaybackController(
    this._playback,
    this._subtitleService, {
    PlayerDataRepository? repository,
    HistoryRepository? history,
    MediaRepository? media,
    PrefsService? prefs,
  }) {
    _repo = repository;
    _history = history;
    _media = media;
    _prefs = prefs;
    _positionListener = () {
      _maybeRotateSession();
      _maybeLoop();
      _maybeEndOfMediaSleep();
      _maybeNotify();
      _maybeSavePosition();
    };
    _playback.position.addListener(_positionListener!);
    _playback.isCompleted.addListener(_maybeEndOfMediaSleep);
  }

  final PlaybackService _playback;
  final SubtitleService _subtitleService;
  PlayerDataRepository? _repo;
  HistoryRepository? _history;
  MediaRepository? _media;
  PrefsService? _prefs;
  VoidCallback? _positionListener;

  String? _mediaId;
  String? get currentMediaId => _mediaId;

  String? _sessionMediaId;
  Duration _sessionStart = Duration.zero;
  DateTime? _lastPositionSave;
  static const _positionSaveInterval = Duration(seconds: 30);

  void _beginSession(String mediaId) {
    _sessionMediaId = mediaId;
    _sessionStart = _playback.position.value;
    _lastPositionSave = DateTime.now();
  }

  void _recordSession() {
    final mediaId = _sessionMediaId;
    if (mediaId == null) return;
    _sessionMediaId = null;
    final history = _history;
    final media = _media;
    if (_prefs?.incognitoMode == true) {
      _savePosition(mediaId, _playback.position.value);
      return;
    }
    final watchedMs =
        (_playback.position.value - _sessionStart).inMilliseconds.clamp(
          0,
          1 << 30,
        );
    if (watchedMs <= 0) return;
    final total = _playback.duration.value;
    final completed =
        total > Duration.zero && watchedMs >= total.inMilliseconds * 0.9;
    if (history != null) {
      unawaited(
        history.record(
          id: _sessionUuid.v4(),
          mediaId: mediaId,
          durationPlayedMs: watchedMs,
          completed: completed,
        ),
      );
    }
    if (media != null) {
      unawaited(media.recordPlayback(mediaId, playedMs: watchedMs));
    }
    _savePosition(mediaId, _playback.position.value);
  }

  void _maybeSavePosition() {
    final mediaId = _sessionMediaId;
    if (mediaId == null) return;
    final now = DateTime.now();
    final lastSave = _lastPositionSave;
    if (lastSave == null || now.difference(lastSave) >= _positionSaveInterval) {
      _lastPositionSave = now;
      _savePosition(mediaId, _playback.position.value);
    }
  }

  void _savePosition(String mediaId, Duration position) {
    final media = _media;
    if (media == null) return;
    unawaited(media.updatePosition(mediaId, position.inMilliseconds));
  }

  void _maybeRotateSession() {
    final current = _playback.currentMediaId.value;
    if (current != null && current != _sessionMediaId) {
      _recordSession();
      _beginSession(current);
    }
  }

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
    _recordSession();
    await _playback.openItem(item, autoplay: autoplay);
    _mediaId = item.id;
    _beginSession(item.id);
    await _loadPersistedData();
    await _attachSubtitles(item);
    notifyListeners();
  }

  Future<void> openQueue(PlaybackQueue queue, {bool autoplay = true}) async {
    _recordSession();
    await _playback.openQueue(queue, autoplay: autoplay);
    final current = queue.current;
    _mediaId = current?.id;
    if (current != null) {
      _beginSession(current.id);
      await _loadPersistedData();
      await _attachSubtitles(current);
    }
    notifyListeners();
  }

  /// Reloads bookmarks, notes and chapters stored for the currently open item.
  Future<void> _loadPersistedData() async {
    final repo = _repo;
    final mediaId = _mediaId;
    _bookmarks.clear();
    _notes.clear();
    _userChapters.clear();
    if (repo == null || mediaId == null) return;
    _bookmarks.addAll(await repo.bookmarksFor(mediaId));
    _notes.addAll(await repo.notesFor(mediaId));
    _userChapters.addAll(await repo.chaptersFor(mediaId));
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

  static const Duration kSleepFadeDuration = Duration(seconds: 10);

  /// Active [SleepMode], or `null` when no sleep timer is armed.
  SleepMode? sleepMode;

  /// Countdown left for [SleepMode.timer].
  Duration? sleepRemaining;

  /// Whether master volume eases down over the final [kSleepFadeDuration].
  bool sleepFadeOut = true;

  Timer? _sleepTimer;
  double _sleepBaseVolume = 1.0;
  bool _sleepFading = false;

  /// Arms a sleep timer. [duration] is required for [SleepMode.timer];
  /// the end modes pause at the boundary they describe instead.
  void setSleepTimer(
    SleepMode mode, {
    Duration? duration,
    bool fadeOut = true,
  }) {
    if (mode == SleepMode.timer && (duration == null || duration <= Duration.zero)) {
      cancelSleepTimer();
      return;
    }
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepFading = false;
    _sleepBaseVolume = _playback.volume.value;
    sleepMode = mode;
    sleepFadeOut = fadeOut;
    sleepRemaining = mode == SleepMode.timer ? duration : null;
    if (sleepRemaining != null) {
      _sleepTimer = Timer.periodic(const Duration(seconds: 1), _tickSleepTimer);
    }
    notifyListeners();
  }

  /// Disarms any armed sleep timer and restores the volume that was faded.
  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    if (_sleepFading) {
      _sleepFading = false;
      unawaited(_playback.setVolume(_sleepBaseVolume));
    }
    sleepMode = null;
    sleepRemaining = null;
    notifyListeners();
  }

  void _tickSleepTimer(Timer timer) {
    final remaining = sleepRemaining;
    if (remaining == null) {
      timer.cancel();
      _sleepTimer = null;
      return;
    }
    if (remaining <= const Duration(seconds: 1)) {
      unawaited(_finishSleepTimer(timer));
      return;
    }
    sleepRemaining = remaining - const Duration(seconds: 1);
    _applySleepFade();
    notifyListeners();
  }

  Future<void> _finishSleepTimer(Timer timer) async {
    timer.cancel();
    _sleepTimer = null;
    sleepMode = null;
    sleepRemaining = null;
    await _playback.pause();
    if (_sleepFading) {
      _sleepFading = false;
      await _playback.setVolume(_sleepBaseVolume);
    }
    notifyListeners();
  }

  /// Smoothly eases volume toward zero across the final [kSleepFadeDuration].
  void _applySleepFade() {
    final remaining = sleepRemaining;
    if (!sleepFadeOut || remaining == null) return;
    if (remaining > kSleepFadeDuration) return;
    _sleepFading = true;
    final t =
        (remaining.inMilliseconds / kSleepFadeDuration.inMilliseconds).clamp(0.0, 1.0);
    unawaited(_playback.setVolume(_sleepBaseVolume * t));
  }

  /// Pauses at the requested boundary for the end-of-media / end-of-queue modes.
  void _maybeEndOfMediaSleep() {
    final mode = sleepMode;
    if (mode != SleepMode.endOfMedia && mode != SleepMode.endOfQueue) return;
    if (!_playback.isCompleted.value) return;
    if (mode == SleepMode.endOfQueue) {
      final q = _playback.queue.value;
      if (q == null || _playback.currentIndex.value != q.length - 1) return;
    }
    _sleepTimer?.cancel();
    _sleepTimer = null;
    sleepMode = null;
    sleepRemaining = null;
    unawaited(_playback.pause());
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
    _repo?.upsertBookmark(bookmark);
    notifyListeners();
    return bookmark;
  }

  void removeBookmark(String id) {
    _bookmarks.removeWhere((b) => b.id == id);
    _repo?.removeBookmark(id);
    notifyListeners();
  }

  void updateBookmark(String id, {String? label, String? note}) {
    final index = _bookmarks.indexWhere((b) => b.id == id);
    if (index < 0) return;
    final updated = _bookmarks[index].copyWith(
      label: label,
      note: note,
      updatedAt: DateTime.now(),
    );
    _bookmarks[index] = updated;
    _repo?.upsertBookmark(updated);
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Notes
  // ---------------------------------------------------------------------

  final List<PlayerNote> _notes = [];

  List<PlayerNote> get notes => List.unmodifiable(_notes);

  Future<PlayerNote> addNote({
    String? title,
    required String body,
    Duration? position,
  }) async {
    final mediaId = _mediaId ?? _playback.currentMediaId.value ?? 'unknown';
    final note = PlayerNote(
      id: 'nt-${DateTime.now().microsecondsSinceEpoch}',
      mediaId: mediaId,
      title: title,
      body: body,
      position: position ?? _playback.position.value,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _notes.insert(0, note);
    await _repo?.upsertNote(note);
    notifyListeners();
    return note;
  }

  Future<void> updateNote(String id, {String? title, String? body}) async {
    final index = _notes.indexWhere((n) => n.id == id);
    if (index < 0) return;
    final updated = _notes[index].copyWith(
      title: title,
      body: body,
      updatedAt: DateTime.now(),
    );
    _notes[index] = updated;
    await _repo?.upsertNote(updated);
    notifyListeners();
  }

  Future<void> removeNote(String id) async {
    _notes.removeWhere((n) => n.id == id);
    await _repo?.removeNote(id);
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // User chapters
  // ---------------------------------------------------------------------

  final List<UserChapter> _userChapters = [];

  List<UserChapter> get userChapters => List.unmodifiable(_userChapters);

  Future<UserChapter> addChapter(
    String title, {
    Duration? start,
    Duration? end,
  }) async {
    final mediaId = _mediaId ?? _playback.currentMediaId.value ?? 'unknown';
    final chapter = UserChapter(
      id: 'ch-${DateTime.now().microsecondsSinceEpoch}',
      mediaId: mediaId,
      title: title,
      start: start ?? _playback.position.value,
      end: end,
      createdAt: DateTime.now(),
    );
    _userChapters.add(chapter);
    _userChapters.sort((a, b) => a.start.compareTo(b.start));
    await _repo?.upsertChapter(chapter);
    notifyListeners();
    return chapter;
  }

  Future<void> updateChapter(
    String id, {
    String? title,
    Duration? start,
    Duration? end,
  }) async {
    final index = _userChapters.indexWhere((c) => c.id == id);
    if (index < 0) return;
    final updated = _userChapters[index].copyWith(
      title: title,
      start: start,
      end: end,
    );
    _userChapters[index] = updated;
    _userChapters.sort((a, b) => a.start.compareTo(b.start));
    await _repo?.upsertChapter(updated);
    notifyListeners();
  }

  Future<void> removeChapter(String id) async {
    _userChapters.removeWhere((c) => c.id == id);
    await _repo?.removeChapter(id);
    notifyListeners();
  }

  /// Splices evenly-spaced chapters across [duration] for the current item,
  /// skipping positions that already have a user chapter.
  Future<void> autoGenerateChapters(
    Duration duration, {
    Duration interval = const Duration(minutes: 5),
  }) async {
    final mediaId = _mediaId ?? _playback.currentMediaId.value;
    if (mediaId == null) return;
    final intervalMs = interval.inMilliseconds;
    if (intervalMs <= 0 || duration.inMilliseconds < intervalMs) return;
    final existingStarts =
        _userChapters.map((c) => c.start.inMilliseconds).toSet();
    var added = false;
    for (var startMs = 0; startMs < duration.inMilliseconds; startMs += intervalMs) {
      if (existingStarts.contains(startMs)) continue;
      final chapter = UserChapter(
        id: 'ch-${DateTime.now().microsecondsSinceEpoch}-$startMs',
        mediaId: mediaId,
        title: 'Chapter ${(startMs ~/ intervalMs) + 1}',
        start: Duration(milliseconds: startMs),
        end: startMs + intervalMs < duration.inMilliseconds
            ? Duration(milliseconds: startMs + intervalMs)
            : null,
        createdAt: DateTime.now(),
      );
      _userChapters.add(chapter);
      await _repo?.upsertChapter(chapter);
      added = true;
    }
    if (added) {
      _userChapters.sort((a, b) => a.start.compareTo(b.start));
      notifyListeners();
    }
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
    _recordSession();
    _hideTimer?.cancel();
    _gestureClearTimer?.cancel();
    _sleepTimer?.cancel();
    _playback.isCompleted.removeListener(_maybeEndOfMediaSleep);
    if (_positionListener != null) {
      _playback.position.removeListener(_positionListener!);
    }
    super.dispose();
  }
}
