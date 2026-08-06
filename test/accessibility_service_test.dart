import 'package:flutter_test/flutter_test.dart';
import 'package:hikmahplayer/core/services/accessibility_service.dart';
import 'package:hikmahplayer/features/accessibility/domain/models/audio_accessibility.dart';
import 'package:hikmahplayer/features/accessibility/domain/models/audio_cue.dart';
import 'package:hikmahplayer/features/accessibility/domain/models/color_filters.dart';
import 'package:hikmahplayer/features/accessibility/domain/models/gesture_config.dart';
import 'package:hikmahplayer/features/accessibility/domain/models/motion_settings.dart';
import 'package:hikmahplayer/features/accessibility/domain/models/reading_mode.dart';
import 'package:hikmahplayer/features/accessibility/domain/models/session_pacing.dart';
import 'package:hikmahplayer/features/accessibility/domain/models/subtitle_presets.dart';
import 'package:hikmahplayer/features/accessibility/domain/models/ui_mode.dart';

void main() {
  late AccessibilityService service;

  setUp(() {
    service = AccessibilityService();
  });

  tearDown(() {
    service.dispose();
  });

  test('starts at defaults', () {
    expect(service.settings.value.isDefault, isTrue);
    expect(service.settings.value.uiMode, UIMode.standard);
  });

  test('notifies listeners and updates on changes', () {
    var notified = 0;
    service.addListener(() => notified++);
    service.setUIMode(UIMode.simplified);
    expect(notified, 1);
    expect(service.settings.value.uiMode, UIMode.simplified);
  });

  group('subtitles', () {
    test('setSubtitlePreset applies the preset style and id', () {
      service.setSubtitlePreset(SubtitlePreset.largePrint);
      final s = service.settings.value;
      expect(s.subtitlePresetId, 'largePrint');
      expect(s.subtitleStyle.sizeScale, 1.6);
      expect(s.subtitleStyle.bold, isTrue);
    });

    test('setSubtitleStyle marks the style as custom', () {
      service.setSubtitleStyle(
          SubtitlePreset.whiteOnBlack.style.copyWith(fontSize: 40));
      final s = service.settings.value;
      expect(s.subtitlePresetId, 'custom');
      expect(s.subtitleStyle.fontSize, 40);
    });

    test('scaleSubtitles scales the existing style', () {
      service.setSubtitlePreset(SubtitlePreset.whiteOnBlack);
      service.scaleSubtitles(2.0);
      expect(service.settings.value.subtitleStyle.sizeScale, 2.0);
    });
  });

  group('colour filters', () {
    test('setColorBlindness applies matrix and clamps strength', () {
      service.setColorBlindness(ColorBlindnessType.tritanopia, strength: 2.0);
      final s = service.settings.value;
      expect(s.colorBlindnessType, ColorBlindnessType.tritanopia);
      expect(s.colorBlindnessStrength, 1.0);
      expect(s.colorFilterMatrix, hasLength(20));
    });

    test('clearColorBlindness removes the filter', () {
      service.setColorBlindness(ColorBlindnessType.deuteranopia);
      expect(service.settings.value.hasColorFilter, isTrue);
      service.clearColorBlindness();
      expect(service.settings.value.hasColorFilter, isFalse);
    });
  });

  group('motion & photosensitivity', () {
    test('setReduceMotion changes the level', () {
      service.setReduceMotion(ReduceMotionLevel.full);
      expect(service.settings.value.reduceMotion, ReduceMotionLevel.full);
    });

    test('setFlashWarnings toggles the assessor', () {
      final strobe = [0.1, 0.9, 0.1, 0.9, 0.1, 0.9];
      expect(service.assessFlashRisk(strobe), FlashRiskLevel.high);
      service.setFlashWarnings(false);
      expect(service.assessFlashRisk(strobe), isNull);
      service.setFlashWarnings(true);
      expect(service.assessFlashRisk(strobe), FlashRiskLevel.high);
    });
  });

  group('interface modes', () {
    test('toggleFocusMode flips the flag', () {
      expect(service.settings.value.focusMode.enabled, isFalse);
      service.toggleFocusMode();
      expect(service.settings.value.focusMode.enabled, isTrue);
      service.toggleFocusMode();
      expect(service.settings.value.focusMode.enabled, isFalse);
    });
  });

  group('pacing', () {
    test('suggests a break only when due', () {
      service.setPacing(
          const PacingSettings(intervalMinutes: 30, breakDurationMinutes: 5));
      final last = DateTime.utc(2024, 1, 1, 11, 0);
      expect(service.maybeSuggestBreak(
          lastBreak: last, now: DateTime.utc(2024, 1, 1, 11, 15)), isNull);
      final due = DateTime.utc(2024, 1, 1, 11, 30);
      final suggestion = service.maybeSuggestBreak(
          lastBreak: last, now: due, contentTitle: 'Talk');
      expect(suggestion, isNotNull);
      expect(suggestion!.breakMinutes, 5);
      expect(suggestion.contentTitle, 'Talk');
      expect(service.lastBreakSuggestion, same(suggestion));
    });

    test('nextBreakFrom uses the configured interval', () {
      service.setPacing(const PacingSettings(intervalMinutes: 25));
      final from = DateTime.utc(2024, 1, 1, 9, 0);
      expect(service.nextBreakFrom(from), DateTime.utc(2024, 1, 1, 9, 25));
    });

    test('reminders disabled suppress suggestions', () {
      service.setPacing(const PacingSettings(breakRemindersEnabled: false));
      final last = DateTime.utc(2024, 1, 1, 10, 0);
      expect(service.maybeSuggestBreak(
          lastBreak: last, now: DateTime.utc(2024, 1, 1, 12, 0)), isNull);
    });
  });

  group('reading mode', () {
    test('setReadingMode stores the settings', () {
      service.setReadingMode(const ReadingModeSettings(enabled: true, pauseDurationMs: 800));
      final r = service.settings.value.readingMode;
      expect(r.enabled, isTrue);
      expect(r.pauseDurationMs, 800);
    });
  });

  group('audio accessibility', () {
    test('hearing profile and mono downmix are applied', () {
      service.setHearingProfile(HearingProfile.profoundLoss);
      expect(service.settings.value.audio.hearingProfile,
          HearingProfile.profoundLoss);
      service.setMonoDownmix(true);
      expect(service.settings.value.audio.monoDownmix, isTrue);
      expect(service.settings.value.audio.effectiveDialogueBoostDb, 12);
    });
  });

  group('gestures', () {
    test('default actions are available', () {
      expect(service.actionFor(GestureTrigger.singleTap),
          GestureAction.playPause);
    });

    test('bindGesture rebinds a trigger', () {
      service.bindGesture(GestureTrigger.singleTap, GestureAction.volumeUp);
      expect(service.actionFor(GestureTrigger.singleTap),
          GestureAction.volumeUp);
    });

    test('toggleGesture disables a trigger', () {
      service.toggleGesture(GestureTrigger.singleTap);
      expect(service.actionFor(GestureTrigger.singleTap), GestureAction.none);
    });
  });

  group('audio cues', () {
    test('cue toggling is reflected in settings', () {
      expect(service.isAudioCueEnabled(AudioCue.error), isTrue);
      service.setAudioCueEnabled(AudioCue.error, false);
      expect(service.isAudioCueEnabled(AudioCue.error), isFalse);
    });
  });

  test('resetToDefaults restores everything', () {
    service.setSubtitlePreset(SubtitlePreset.dyslexiaFriendly);
    service.setColorBlindness(ColorBlindnessType.protanopia);
    service.setUIMode(UIMode.simplified);
    service.setMonoDownmix(true);
    expect(service.settings.value.isDefault, isFalse);

    service.resetToDefaults();
    expect(service.settings.value.isDefault, isTrue);
  });
}
