import 'package:flutter/foundation.dart';

import '../../features/accessibility/domain/models/accessibility_settings.dart';
import '../../features/accessibility/domain/models/audio_accessibility.dart';
import '../../features/accessibility/domain/models/audio_cue.dart';
import '../../features/accessibility/domain/models/color_filters.dart';
import '../../features/accessibility/domain/models/gesture_config.dart';
import '../../features/accessibility/domain/models/motion_settings.dart';
import '../../features/accessibility/domain/models/reading_mode.dart';
import '../../features/accessibility/domain/models/session_pacing.dart';
import '../../features/accessibility/domain/models/subtitle_presets.dart';
import '../../features/accessibility/domain/models/subtitle_style.dart';
import '../../features/accessibility/domain/models/ui_mode.dart';

/// Central, observable holder of the accessibility configuration.
///
/// The current snapshot lives in [settings] ([ValueNotifier]); the UI watches
/// it to re-theme subtitles, apply colour filters, switch to simplified mode,
/// etc. All setters publish a new immutable [AccessibilitySettings] snapshot.
class AccessibilityService extends ChangeNotifier {
  final ValueNotifier<AccessibilitySettings> settings =
      ValueNotifier<AccessibilitySettings>(AccessibilitySettings.defaults);

  final SessionPacingCalculator _pacingCalculator =
      const SessionPacingCalculator();

  /// The last produced break suggestion (may be stale).
  BreakSuggestion? lastBreakSuggestion;

  // ---------------------------------------------------------------------
  // Subtitle styling
  // ---------------------------------------------------------------------

  void setSubtitlePreset(SubtitlePreset preset) {
    _update(
      settings.value.copyWith(
        subtitleStyle: preset.style,
        subtitlePresetId: preset.id,
      ),
    );
  }

  /// Applies free-form customisation; the preset id becomes `custom`.
  void setSubtitleStyle(SubtitleStyle style) {
    _update(
      settings.value.copyWith(
        subtitleStyle: style,
        subtitlePresetId: customSubtitleStyleId,
      ),
    );
  }

  /// Scales the current subtitle size (relative to its preset).
  void scaleSubtitles(double factor) {
    final current = settings.value.subtitleStyle;
    setSubtitleStyle(current.copyWith(sizeScale: factor));
  }

  // ---------------------------------------------------------------------
  // Colour filters
  // ---------------------------------------------------------------------

  void setColorBlindness(ColorBlindnessType type, {double strength = 1.0}) {
    _update(
      settings.value.copyWith(
        colorBlindnessType: type,
        colorBlindnessStrength: strength.clamp(0.0, 1.0),
      ),
    );
  }

  void clearColorBlindness() {
    _update(settings.value.copyWith(clearColorBlindness: true));
  }

  // ---------------------------------------------------------------------
  // Motion / photosensitivity
  // ---------------------------------------------------------------------

  void setReduceMotion(ReduceMotionLevel level) {
    _update(settings.value.copyWith(reduceMotion: level));
  }

  void setPhotosensitivity(PhotosensitivitySettings value) {
    _update(settings.value.copyWith(photosensitivity: value));
  }

  void setFlashWarnings(bool enabled) {
    final p = settings.value.photosensitivity;
    setPhotosensitivity(p.copyWith(flashWarningsEnabled: enabled));
  }

  /// Evaluates a brightness sample sequence; `null` if warnings are disabled.
  FlashRiskLevel? assessFlashRisk(List<double> luminance) {
    final p = settings.value.photosensitivity;
    if (!p.flashWarningsEnabled) return null;
    return FlashRiskAssessor(
      maxTransitionsPerWindow: p.maxTransitionsPerWindow,
      windowSize: p.windowSize,
    ).evaluate(luminance);
  }

  // ---------------------------------------------------------------------
  // Interface modes
  // ---------------------------------------------------------------------

  void setUIMode(UIMode mode) {
    _update(settings.value.copyWith(uiMode: mode));
  }

  void setFocusMode(FocusModeSettings value) {
    _update(settings.value.copyWith(focusMode: value));
  }

  void toggleFocusMode() {
    final f = settings.value.focusMode;
    setFocusMode(f.copyWith(enabled: !f.enabled));
  }

  // ---------------------------------------------------------------------
  // Pacing / breaks
  // ---------------------------------------------------------------------

  void setPacing(PacingSettings value) {
    _update(settings.value.copyWith(pacing: value));
  }

  /// Next break due time given [from] (defaults to now) and the configured
  /// interval.
  DateTime nextBreakFrom(DateTime? from) {
    final pacing = settings.value.pacing;
    return _pacingCalculator.nextBreak(
      from: from ?? DateTime.now(),
      intervalMinutes: pacing.intervalMinutes,
    );
  }

  /// Whether a break is due given the last break time.
  bool isBreakDue(DateTime lastBreak, {DateTime? now}) {
    final pacing = settings.value.pacing;
    return _pacingCalculator.isBreakDue(
      lastBreak: lastBreak,
      now: now ?? DateTime.now(),
      intervalMinutes: pacing.intervalMinutes,
    );
  }

  /// Produces a suggestion (and remembers it) when a break is due.
  BreakSuggestion? maybeSuggestBreak({
    required DateTime lastBreak,
    DateTime? now,
    String? contentTitle,
  }) {
    if (!settings.value.pacing.breakRemindersEnabled) return null;
    if (!isBreakDue(lastBreak, now: now)) return null;
    final pacing = settings.value.pacing;
    lastBreakSuggestion = _pacingCalculator.suggest(
      reason: BreakReason.timed,
      dueTime: now ?? DateTime.now(),
      breakMinutes: pacing.breakDurationMinutes,
      contentTitle: contentTitle,
    );
    return lastBreakSuggestion;
  }

  // ---------------------------------------------------------------------
  // Reading mode
  // ---------------------------------------------------------------------

  void setReadingMode(ReadingModeSettings value) {
    _update(settings.value.copyWith(readingMode: value));
  }

  // ---------------------------------------------------------------------
  // Audio accessibility
  // ---------------------------------------------------------------------

  void setAudioAccessibility(AudioAccessibilitySettings value) {
    _update(settings.value.copyWith(audio: value));
  }

  void setHearingProfile(HearingProfile profile) {
    setAudioAccessibility(settings.value.audio.copyWith(hearingProfile: profile));
  }

  void setMonoDownmix(bool enabled) {
    setAudioAccessibility(settings.value.audio.copyWith(monoDownmix: enabled));
  }

  // ---------------------------------------------------------------------
  // Gestures
  // ---------------------------------------------------------------------

  void setGestureConfig(GestureConfig value) {
    _update(settings.value.copyWith(gestures: value));
  }

  void bindGesture(GestureTrigger trigger, GestureAction action) {
    setGestureConfig(settings.value.gestures.withBinding(trigger, action));
  }

  void toggleGesture(GestureTrigger trigger) {
    setGestureConfig(settings.value.gestures.toggleBinding(trigger));
  }

  GestureAction actionFor(GestureTrigger trigger) =>
      settings.value.gestures.actionFor(trigger);

  // ---------------------------------------------------------------------
  // Audio cues
  // ---------------------------------------------------------------------

  void setAudioCues(AudioCueSettings value) {
    _update(settings.value.copyWith(audioCues: value));
  }

  void setAudioCueEnabled(AudioCue cue, bool enabled) {
    setAudioCues(settings.value.audioCues.setEnabled(cue, enabled));
  }

  bool isAudioCueEnabled(AudioCue cue) =>
      settings.value.audioCues.isEnabled(cue);

  // ---------------------------------------------------------------------
  // General
  // ---------------------------------------------------------------------

  void resetToDefaults() {
    _update(AccessibilitySettings.defaults);
  }

  void _update(AccessibilitySettings next) {
    settings.value = next;
    notifyListeners();
  }

  @override
  void dispose() {
    settings.dispose();
    super.dispose();
  }
}
