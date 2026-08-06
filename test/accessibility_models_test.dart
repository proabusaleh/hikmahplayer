import 'package:flutter_test/flutter_test.dart';
import 'package:hikmahplayer/features/accessibility/domain/models/accessibility_settings.dart';
import 'package:hikmahplayer/features/accessibility/domain/models/audio_accessibility.dart';
import 'package:hikmahplayer/features/accessibility/domain/models/audio_cue.dart';
import 'package:hikmahplayer/features/accessibility/domain/models/color_filters.dart';
import 'package:hikmahplayer/features/accessibility/domain/models/gesture_config.dart';
import 'package:hikmahplayer/features/accessibility/domain/models/motion_settings.dart';
import 'package:hikmahplayer/features/accessibility/domain/models/reading_mode.dart';
import 'package:hikmahplayer/features/accessibility/domain/models/session_pacing.dart';
import 'package:hikmahplayer/features/accessibility/domain/models/subtitle_presets.dart';
import 'package:hikmahplayer/features/accessibility/domain/models/subtitle_style.dart';
import 'package:hikmahplayer/features/accessibility/domain/models/ui_mode.dart';

void main() {
  group('SubtitlePreset', () {
    test('ships 20+ presets', () {
      expect(SubtitlePreset.presetCount, greaterThanOrEqualTo(20));
      expect(SubtitlePreset.values, hasLength(SubtitlePreset.presetCount));
    });

    test('every preset has a unique id and clears WCAG contrast', () {
      final ids = <String>{};
      for (final preset in SubtitlePreset.values) {
        expect(preset.style.id, preset.id);
        expect(ids.add(preset.id), isTrue, reason: 'duplicate id ${preset.id}');
        final ratio = preset.style.contrastRatio;
        expect(ratio, greaterThanOrEqualTo(3.0),
            reason: '${preset.label} has low contrast $ratio');
      }
    });

    test('byId finds presets and is null for unknown ids', () {
      expect(SubtitlePreset.byId('largePrint'), SubtitlePreset.largePrint);
      expect(SubtitlePreset.byId('nope'), isNull);
    });

    test('effective font size combines base and scale', () {
      expect(SubtitlePreset.largePrint.style.effectiveFontSize,
          closeTo(24 * 1.6, 0.001));
    });

    test('effectiveBackgroundColor composites over black', () {
      const ghost = SubtitleStyle(
        id: 'x',
        label: 'x',
        color: 0xFFFFFFFF,
        backgroundColor: 0x80FFFFFF,
        backgroundOpacity: 0.5,
      );
      // alpha 0x80 (128/255) then * 0.5 = 0.25 opacity over black.
      expect(ghost.effectiveBackgroundColor, isNotNull);
      final channel = (ghost.effectiveBackgroundColor! >> 16) & 0xFF;
      expect(channel, closeTo(0x3F, 1));
    });
  });

  group('SubtitleStyle', () {
    test('contrast ratio is symmetric and at least 1', () {
      expect(SubtitleStyle.contrastRatioBetween(0xFFFFFFFF, 0xFF000000),
          greaterThan(15));
      expect(SubtitleStyle.contrastRatioBetween(0xFF000000, 0xFFFFFFFF),
          greaterThan(15));
      expect(SubtitleStyle.contrastRatioBetween(0xFF888888, 0xFF888888),
          closeTo(1.0, 0.01));
    });

    test('json round-trip', () {
      const style = SubtitleStyle(
        id: 's1',
        label: 'Test',
        fontSize: 30,
        bold: true,
        color: 0xFFFF0000,
        backgroundColor: 0xFF000000,
        outlineWidth: 2,
        letterSpacing: 1,
        align: SubtitleAlign.left,
        verticalPosition: 0.1,
      );
      final restored = SubtitleStyle.fromJson(style.toJson());
      expect(restored.id, 's1');
      expect(restored.bold, isTrue);
      expect(restored.align, SubtitleAlign.left);
      expect(restored.effectiveFontSize, 30);
    });

    test('copyWith can clear the background', () {
      const style = SubtitleStyle(
          id: 's', label: 's', backgroundColor: 0xFF000000);
      expect(style.copyWith(clearBackground: true).backgroundColor, isNull);
    });
  });

  group('ColorBlindnessFilter', () {
    test('strength 0 equals the identity matrix', () {
      for (final type in ColorBlindnessType.values) {
        final m = ColorBlindnessFilter.matrix(type, strength: 0);
        expect(m, orderedEquals(ColorBlindnessFilter.identity));
      }
    });

    test('correction matrices are 20-element RGBA matrices', () {
      for (final type in ColorBlindnessType.values) {
        final m = ColorBlindnessFilter.matrix(type);
        expect(m, hasLength(20));
        expect(m[18], 1); // alpha row preserved (0 0 0 1 0)
      }
    });

    test('achromatopsia collapses to luminance', () {
      final m = ColorBlindnessFilter.matrixFor(ColorBlindnessType.achromatopsia);
      expect(m[0], closeTo(0.2126, 0.001));
      expect(m[2], closeTo(0.0722, 0.001));
    });

    test('matrix scales between identity and correction', () {
      final half = ColorBlindnessFilter.matrix(
          ColorBlindnessType.protanopia, strength: 0.5);
      final full = ColorBlindnessFilter.matrix(ColorBlindnessType.protanopia);
      for (var i = 0; i < 9; i++) {
        final mid = (ColorBlindnessFilter.identity[i] + full[i]) / 2;
        expect(half[i], closeTo(mid, 0.001));
      }
    });
  });

  group('FlashRiskAssessor', () {
    test('steady brightness is safe', () {
      const assessor = FlashRiskAssessor();
      expect(assessor.evaluate([0.2, 0.2, 0.2, 0.2]), FlashRiskLevel.safe);
    });

    test('single change is caution', () {
      const assessor = FlashRiskAssessor();
      expect(assessor.evaluate([0.1, 0.9, 0.1, 0.1]),
          FlashRiskLevel.caution);
    });

    test('rapid strobe is high risk', () {
      const assessor = FlashRiskAssessor(
        transitionThreshold: 0.4,
        maxTransitionsPerWindow: 3,
        windowSize: 6,
      );
      final strobe = [0.1, 0.9, 0.1, 0.9, 0.1, 0.9, 0.1, 0.9];
      expect(assessor.evaluate(strobe), FlashRiskLevel.high);
    });
  });

  group('SessionPacingCalculator', () {
    test('nextBreak adds the interval', () {
      const calc = SessionPacingCalculator();
      final from = DateTime.utc(2024, 1, 1, 10, 0);
      expect(calc.nextBreak(from: from, intervalMinutes: 50),
          DateTime.utc(2024, 1, 1, 10, 50));
    });

    test('isBreakDue respects the interval', () {
      const calc = SessionPacingCalculator();
      final last = DateTime.utc(2024, 1, 1, 10, 0);
      expect(calc.isBreakDue(
          lastBreak: last,
          now: DateTime.utc(2024, 1, 1, 10, 49),
          intervalMinutes: 50), isFalse);
      expect(calc.isBreakDue(
          lastBreak: last,
          now: DateTime.utc(2024, 1, 1, 10, 50),
          intervalMinutes: 50), isTrue);
    });

    test('suggestion is due and carries metadata', () {
      const calc = SessionPacingCalculator();
      final due = DateTime.utc(2024, 1, 1, 11, 0);
      final suggestion = calc.suggest(
        reason: BreakReason.contentLength,
        dueTime: due,
        breakMinutes: 10,
        contentTitle: 'Lecture 3',
      );
      expect(suggestion.isDue(DateTime.utc(2024, 1, 1, 11, 0, 1)), isTrue);
      expect(suggestion.isDue(DateTime.utc(2024, 1, 1, 10, 59)), isFalse);
      expect(suggestion.contentTitle, 'Lecture 3');
    });
  });

  group('AudioAccessibilitySettings', () {
    test('effective boost combines profile and manual', () {
      const s = AudioAccessibilitySettings(
        hearingProfile: HearingProfile.moderateLoss,
        dialogueBoostDb: 4,
      );
      expect(s.effectiveDialogueBoostDb, 10);
    });

    test('hearing loss profiles escalate boost', () {
      final levels = [
        HearingProfile.standard,
        HearingProfile.mildLoss,
        HearingProfile.moderateLoss,
        HearingProfile.severeLoss,
        HearingProfile.profoundLoss,
      ];
      for (var i = 1; i < levels.length; i++) {
        expect(levels[i].dialogueBoostDb,
            greaterThanOrEqualTo(levels[i - 1].dialogueBoostDb));
      }
      expect(HearingProfile.profoundLoss.dialogueBoostDb, 12);
    });

    test('cochlear implant emphasises high frequencies', () {
      expect(HearingProfile.cochlearImplant.highFrequencyEmphasis, isTrue);
      expect(HearingProfile.cochlearImplant.enableCompression, isTrue);
    });

    test('json round-trip', () {
      const s = AudioAccessibilitySettings(
        monoDownmix: true,
        hearingProfile: HearingProfile.cochlearImplant,
      );
      final restored = AudioAccessibilitySettings.fromJson(s.toJson());
      expect(restored.monoDownmix, isTrue);
      expect(restored.hearingProfile, HearingProfile.cochlearImplant);
    });
  });

  group('AudioCueSettings', () {
    test('defaults enable cues and overrides toggle them', () {
      const s = AudioCueSettings();
      expect(s.isEnabled(AudioCue.error), isTrue);
      final off = s.setEnabled(AudioCue.error, false);
      expect(off.isEnabled(AudioCue.error), isFalse);
      expect(off.isEnabled(AudioCue.warning), isTrue);
    });

    test('master switch disables everything', () {
      const s = AudioCueSettings(enabled: false);
      expect(s.isEnabled(AudioCue.error), isFalse);
    });

    test('json round-trip', () {
      const s = AudioCueSettings(overrides: {AudioCue.error: false});
      final restored = AudioCueSettings.fromJson(s.toJson());
      expect(restored.isEnabled(AudioCue.error), isFalse);
    });
  });

  group('GestureConfig', () {
    test('defaults bind common gestures', () {
      const config = GestureConfig.defaults;
      expect(config.actionFor(GestureTrigger.singleTap), GestureAction.playPause);
      expect(config.actionFor(GestureTrigger.swipeRight), GestureAction.seekForward);
    });

    test('customisation can rebind a gesture', () {
      const config = GestureConfig.defaults;
      final rebound = config.withBinding(
          GestureTrigger.swipeLeft, GestureAction.volumeDown);
      expect(rebound.actionFor(GestureTrigger.swipeLeft), GestureAction.volumeDown);
    });

    test('disabled trigger or master switch returns none', () {
      const config = GestureConfig.defaults;
      expect(config.toggleBinding(GestureTrigger.doubleTap)
          .actionFor(GestureTrigger.doubleTap), GestureAction.none);
      final off = config.copyWith(customGesturesEnabled: false);
      expect(off.actionFor(GestureTrigger.singleTap), GestureAction.none);
    });

    test('json round-trip', () {
      final config = GestureConfig.defaults
          .withBinding(GestureTrigger.longPress, GestureAction.volumeUp);
      final restored = GestureConfig.fromJson(config.toJson());
      expect(restored.actionFor(GestureTrigger.longPress), GestureAction.volumeUp);
    });
  });

  group('AccessibilitySettings', () {
    test('defaults have no colour filter', () {
      const s = AccessibilitySettings.defaults;
      expect(s.hasColorFilter, isFalse);
      expect(s.colorFilterMatrix, isNull);
    });

    test('copyWith clears the colour filter', () {
      const s = AccessibilitySettings(
        colorBlindnessType: ColorBlindnessType.deuteranopia,
        colorBlindnessStrength: 1,
      );
      expect(s.hasColorFilter, isTrue);
      expect(s.colorFilterMatrix, hasLength(20));
      final cleared = s.copyWith(clearColorBlindness: true);
      expect(cleared.hasColorFilter, isFalse);
    });

    test('defaults isDefault, customised is not', () {
      expect(const AccessibilitySettings().isDefault, isTrue);
      final custom = const AccessibilitySettings().copyWith(uiMode: UIMode.simplified);
      expect(custom.isDefault, isFalse);
    });

    test('full json round-trip', () {
      final custom = AccessibilitySettings.defaults.copyWith(
        subtitleStyle: SubtitlePreset.dyslexiaFriendly.style,
        subtitlePresetId: SubtitlePreset.dyslexiaFriendly.id,
        colorBlindnessType: ColorBlindnessType.protanopia,
        colorBlindnessStrength: 0.7,
        reduceMotion: ReduceMotionLevel.medium,
        uiMode: UIMode.simplified,
        focusMode: const FocusModeSettings(enabled: true),
        pacing: const PacingSettings(intervalMinutes: 30),
        readingMode: const ReadingModeSettings(enabled: true),
        audio: const AudioAccessibilitySettings(monoDownmix: true),
        audioCues: const AudioCueSettings(enabled: false),
      );
      final restored = AccessibilitySettings.fromJson(custom.toJson());
      expect(restored.subtitlePresetId, 'dyslexiaFriendly');
      expect(restored.colorBlindnessStrength, 0.7);
      expect(restored.reduceMotion, ReduceMotionLevel.medium);
      expect(restored.uiMode, UIMode.simplified);
      expect(restored.focusMode.enabled, isTrue);
      expect(restored.pacing.intervalMinutes, 30);
      expect(restored.readingMode.enabled, isTrue);
      expect(restored.audio.monoDownmix, isTrue);
      expect(restored.audioCues.enabled, isFalse);
    });
  });
}
