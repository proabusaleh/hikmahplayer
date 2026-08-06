import 'subtitle_style.dart';

/// Shared default style (also the app's default subtitle theme).
const SubtitleStyle whiteOnBlackSubtitleStyle = SubtitleStyle(
  id: 'whiteOnBlack',
  label: 'White on black',
  color: 0xFFFFFFFF,
  backgroundColor: 0xFF000000,
);

/// A named high-contrast subtitle theme.
///
/// Exposed as an object with static const instances (rather than an enum) so
/// the backing [SubtitleStyle] is a constant expression usable as a default
/// value and from const constructors. Iterate with [values].
class SubtitlePreset {
  /// Human readable preset name.
  final String label;

  /// The [SubtitleStyle] backing this preset.
  final SubtitleStyle style;

  const SubtitlePreset(this.label, this.style);

  /// Id of the preset's style (mirrors [SubtitleStyle.id]).
  String get id => style.id;

  static const whiteOnBlack = SubtitlePreset('White on black', whiteOnBlackSubtitleStyle);

  static const yellowOnBlack = SubtitlePreset('Yellow on black', SubtitleStyle(
        id: 'yellowOnBlack', label: 'Yellow on black', color: 0xFFFFEB3B,
        backgroundColor: 0xFF000000, bold: true));

  static const cyanOnBlack = SubtitlePreset('Cyan on black', SubtitleStyle(
        id: 'cyanOnBlack', label: 'Cyan on black', color: 0xFF00E5FF,
        backgroundColor: 0xFF000000));

  static const whiteOnBlue = SubtitlePreset('White on blue', SubtitleStyle(
        id: 'whiteOnBlue', label: 'White on blue', color: 0xFFFFFFFF,
        backgroundColor: 0xFF0033CC, bold: true));

  static const yellowOnNavy = SubtitlePreset('Yellow on navy', SubtitleStyle(
        id: 'yellowOnNavy', label: 'Yellow on navy', color: 0xFFFFEB3B,
        backgroundColor: 0xFF001A66));

  static const blackOnWhite = SubtitlePreset('Black on white', SubtitleStyle(
        id: 'blackOnWhite', label: 'Black on white', color: 0xFF000000,
        backgroundColor: 0xFFFFFFFF));

  static const blackOnYellow = SubtitlePreset('Black on yellow', SubtitleStyle(
        id: 'blackOnYellow', label: 'Black on yellow', color: 0xFF000000,
        backgroundColor: 0xFFFFD600, bold: true));

  static const whiteOnRed = SubtitlePreset('White on red', SubtitleStyle(
        id: 'whiteOnRed', label: 'White on red', color: 0xFFFFFFFF,
        backgroundColor: 0xFFCC0000, bold: true));

  static const blackOnCyan = SubtitlePreset('Black on cyan', SubtitleStyle(
        id: 'blackOnCyan', label: 'Black on cyan', color: 0xFF000000,
        backgroundColor: 0xFF00CCCC));

  static const whiteOnGreen = SubtitlePreset('White on green', SubtitleStyle(
        id: 'whiteOnGreen', label: 'White on green', color: 0xFFFFFFFF,
        backgroundColor: 0xFF008000, bold: true));

  static const yellowOnPurple = SubtitlePreset('Yellow on purple', SubtitleStyle(
        id: 'yellowOnPurple', label: 'Yellow on purple', color: 0xFFFFE81C,
        backgroundColor: 0xFF4B0082));

  static const blackOnOrange = SubtitlePreset('Black on orange', SubtitleStyle(
        id: 'blackOnOrange', label: 'Black on orange', color: 0xFF000000,
        backgroundColor: 0xFFFF8800));

  static const whiteOnBrown = SubtitlePreset('White on brown', SubtitleStyle(
        id: 'whiteOnBrown', label: 'White on brown', color: 0xFFFFFFFF,
        backgroundColor: 0xFF6B3A00, bold: true));

  static const blueOnWhite = SubtitlePreset('Blue on white', SubtitleStyle(
        id: 'blueOnWhite', label: 'Blue on white', color: 0xFF0033CC,
        backgroundColor: 0xFFFFFFFF, bold: true));

  static const whiteOnNavy = SubtitlePreset('White on navy', SubtitleStyle(
        id: 'whiteOnNavy', label: 'White on navy', color: 0xFFFFFFFF,
        backgroundColor: 0xFF000033));

  static const mintOnBlack = SubtitlePreset('Mint on black', SubtitleStyle(
        id: 'mintOnBlack', label: 'Mint on black', color: 0xFF7FFFD4,
        backgroundColor: 0xFF000000));

  static const pinkOnBlack = SubtitlePreset('Pink on black', SubtitleStyle(
        id: 'pinkOnBlack', label: 'Pink on black', color: 0xFFFF9EC4,
        backgroundColor: 0xFF000000));

  static const sandOnDark = SubtitlePreset('Sand on dark', SubtitleStyle(
        id: 'sandOnDark', label: 'Sand on dark', color: 0xFFFFE8C8,
        backgroundColor: 0xFF26221C));

  static const classicDvd = SubtitlePreset('Classic DVD', SubtitleStyle(
        id: 'classicDvd', label: 'Classic DVD', color: 0xFFFFFFFF,
        outlineColor: 0xFF000000, outlineWidth: 3));

  static const broadcastDefault = SubtitlePreset('Broadcast default', SubtitleStyle(
        id: 'broadcastDefault', label: 'Broadcast default', color: 0xFFFFFFFF,
        outlineColor: 0xFF000000, outlineWidth: 2, shadow: true));

  static const highContrastOutline = SubtitlePreset('High contrast outline', SubtitleStyle(
        id: 'highContrastOutline', label: 'High contrast outline', color: 0xFFFFFFFF,
        outlineColor: 0xFF000000, outlineWidth: 4, bold: true));

  static const subtleGhost = SubtitlePreset('Subtle ghost', SubtitleStyle(
        id: 'subtleGhost', label: 'Subtle ghost', color: 0xFFFFFFFF,
        backgroundColor: 0x99FFFFFF, backgroundOpacity: 0.45));

  static const colorBlindFriendly = SubtitlePreset('Colour-blind friendly', SubtitleStyle(
        id: 'colorBlindFriendly', label: 'Colour-blind friendly', color: 0xFFFFFD54,
        backgroundColor: 0xFF000000, bold: true, sizeScale: 1.15));

  static const nightMode = SubtitlePreset('Night mode', SubtitleStyle(
        id: 'nightMode', label: 'Night mode', color: 0xFFBDBDBD,
        backgroundColor: 0xFF0A0A0A));

  static const largePrint = SubtitlePreset('Large print', SubtitleStyle(
        id: 'largePrint', label: 'Large print', color: 0xFFFFFFFF,
        backgroundColor: 0xFF000000, bold: true, sizeScale: 1.6));

  static const dyslexiaFriendly = SubtitlePreset('Dyslexia friendly', SubtitleStyle(
        id: 'dyslexiaFriendly', label: 'Dyslexia friendly', color: 0xFFFFCC99,
        backgroundColor: 0xFF000000, bold: true, letterSpacing: 1.5,
        sizeScale: 1.25));

  /// All presets, in display order.
  static const List<SubtitlePreset> values = [
    whiteOnBlack, yellowOnBlack, cyanOnBlack, whiteOnBlue, yellowOnNavy,
    blackOnWhite, blackOnYellow, whiteOnRed, blackOnCyan, whiteOnGreen,
    yellowOnPurple, blackOnOrange, whiteOnBrown, blueOnWhite, whiteOnNavy,
    mintOnBlack, pinkOnBlack, sandOnDark, classicDvd, broadcastDefault,
    highContrastOutline, subtleGhost, colorBlindFriendly, nightMode, largePrint,
    dyslexiaFriendly,
  ];

  /// Number of built-in presets (guaranteed 20+).
  static int get presetCount => values.length;

  /// Looks a preset up by style id, or `null`.
  static SubtitlePreset? byId(String id) {
    for (final preset in values) {
      if (preset.id == id) return preset;
    }
    return null;
  }

  @override
  String toString() => 'SubtitlePreset($label)';
}
