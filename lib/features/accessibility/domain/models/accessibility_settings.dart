import 'audio_accessibility.dart';
import 'audio_cue.dart';
import 'color_filters.dart';
import 'gesture_config.dart';
import 'motion_settings.dart';
import 'reading_mode.dart';
import 'session_pacing.dart';
import 'subtitle_presets.dart';
import 'subtitle_style.dart';
import 'ui_mode.dart';

/// Sentinel id used when the user customised subtitles beyond any preset.
const String customSubtitleStyleId = 'custom';

/// The complete, serialisable accessibility configuration.
///
/// One object holds every engine-agnostic accessibility preference so a single
/// snapshot can be persisted, diffed and applied by the [AccessibilityService].
class AccessibilitySettings {
  /// Currently effective subtitle style.
  final SubtitleStyle subtitleStyle;

  /// Id of the [SubtitlePreset] backing [subtitleStyle], or
  /// [customSubtitleStyleId].
  final String subtitlePresetId;

  /// Active colour-blindness correction (`null` = no filter).
  final ColorBlindnessType? colorBlindnessType;

  /// Correction strength `0..1` (meaningful only with [colorBlindnessType]).
  final double colorBlindnessStrength;

  final ReduceMotionLevel reduceMotion;
  final PhotosensitivitySettings photosensitivity;
  final UIMode uiMode;
  final FocusModeSettings focusMode;
  final PacingSettings pacing;
  final ReadingModeSettings readingMode;
  final AudioAccessibilitySettings audio;
  final GestureConfig gestures;
  final AudioCueSettings audioCues;

  const AccessibilitySettings({
    this.subtitleStyle = whiteOnBlackSubtitleStyle,
    this.subtitlePresetId = _defaultSubtitlePresetId,
    this.colorBlindnessType,
    this.colorBlindnessStrength = 0,
    this.reduceMotion = ReduceMotionLevel.none,
    this.photosensitivity = const PhotosensitivitySettings(),
    this.uiMode = UIMode.standard,
    this.focusMode = const FocusModeSettings(),
    this.pacing = const PacingSettings(),
    this.readingMode = const ReadingModeSettings(),
    this.audio = const AudioAccessibilitySettings(),
    this.gestures = GestureConfig.defaults,
    this.audioCues = const AudioCueSettings(),
  });

  static const String _defaultSubtitlePresetId = 'whiteOnBlack';

  static const AccessibilitySettings defaults = AccessibilitySettings();

  /// Whether a colour filter is applied.
  bool get hasColorFilter => colorBlindnessType != null && colorBlindnessStrength > 0;

  /// The RGBA matrix to apply (`null` when no filter).
  List<double>? get colorFilterMatrix {
    final type = colorBlindnessType;
    if (type == null) return null;
    return ColorBlindnessFilter.matrix(type, strength: colorBlindnessStrength);
  }

  AccessibilitySettings copyWith({
    SubtitleStyle? subtitleStyle,
    String? subtitlePresetId,
    ColorBlindnessType? colorBlindnessType,
    double? colorBlindnessStrength,
    ReduceMotionLevel? reduceMotion,
    PhotosensitivitySettings? photosensitivity,
    UIMode? uiMode,
    FocusModeSettings? focusMode,
    PacingSettings? pacing,
    ReadingModeSettings? readingMode,
    AudioAccessibilitySettings? audio,
    GestureConfig? gestures,
    AudioCueSettings? audioCues,
    bool clearColorBlindness = false,
  }) {
    return AccessibilitySettings(
      subtitleStyle: subtitleStyle ?? this.subtitleStyle,
      subtitlePresetId: subtitlePresetId ?? this.subtitlePresetId,
      colorBlindnessType:
          clearColorBlindness ? null : colorBlindnessType ?? this.colorBlindnessType,
      colorBlindnessStrength:
          colorBlindnessStrength ?? this.colorBlindnessStrength,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      photosensitivity: photosensitivity ?? this.photosensitivity,
      uiMode: uiMode ?? this.uiMode,
      focusMode: focusMode ?? this.focusMode,
      pacing: pacing ?? this.pacing,
      readingMode: readingMode ?? this.readingMode,
      audio: audio ?? this.audio,
      gestures: gestures ?? this.gestures,
      audioCues: audioCues ?? this.audioCues,
    );
  }

  Map<String, dynamic> toJson() => {
        'subtitleStyle': subtitleStyle.toJson(),
        'subtitlePresetId': subtitlePresetId,
        'colorBlindnessType': colorBlindnessType?.name,
        'colorBlindnessStrength': colorBlindnessStrength,
        'reduceMotion': reduceMotion.name,
        'photosensitivity': photosensitivity.toJson(),
        'uiMode': uiMode.name,
        'focusMode': focusMode.toJson(),
        'pacing': pacing.toJson(),
        'readingMode': readingMode.toJson(),
        'audio': audio.toJson(),
        'gestures': gestures.toJson(),
        'audioCues': audioCues.toJson(),
      };

  factory AccessibilitySettings.fromJson(Map<String, dynamic> json) {
    return AccessibilitySettings(
      subtitleStyle: SubtitleStyle.fromJson(
          (json['subtitleStyle'] as Map).cast<String, dynamic>()),
      subtitlePresetId: json['subtitlePresetId'] as String? ??
          _defaultSubtitlePresetId,
      colorBlindnessType: json['colorBlindnessType'] == null
          ? null
          : ColorBlindnessType.values
              .asNameMap()[json['colorBlindnessType']],
      colorBlindnessStrength:
          (json['colorBlindnessStrength'] as num?)?.toDouble() ?? 0,
      reduceMotion: ReduceMotionLevel.values
              .asNameMap()[json['reduceMotion']] ??
          ReduceMotionLevel.none,
      photosensitivity: PhotosensitivitySettings.fromJson(
          (json['photosensitivity'] as Map? ?? const {}).cast<String, dynamic>()),
      uiMode: UIMode.values.asNameMap()[json['uiMode']] ?? UIMode.standard,
      focusMode: FocusModeSettings.fromJson(
          (json['focusMode'] as Map? ?? const {}).cast<String, dynamic>()),
      pacing: PacingSettings.fromJson(
          (json['pacing'] as Map? ?? const {}).cast<String, dynamic>()),
      readingMode: ReadingModeSettings.fromJson(
          (json['readingMode'] as Map? ?? const {}).cast<String, dynamic>()),
      audio: AudioAccessibilitySettings.fromJson(
          (json['audio'] as Map? ?? const {}).cast<String, dynamic>()),
      gestures: GestureConfig.fromJson(
          (json['gestures'] as Map? ?? const {}).cast<String, dynamic>()),
      audioCues: AudioCueSettings.fromJson(
          (json['audioCues'] as Map? ?? const {}).cast<String, dynamic>()),
    );
  }

  /// Whether any accessibility feature deviates from the defaults (used to
  /// surface a "reset to defaults" affordance).
  bool get isDefault => _deepEquals(toJson(), defaults.toJson());

  static bool _deepEquals(Object? a, Object? b) {
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final key in a.keys) {
        if (!_deepEquals(a[key], b[key])) return false;
      }
      return true;
    }
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (!_deepEquals(a[i], b[i])) return false;
      }
      return true;
    }
    return a == b;
  }
}
