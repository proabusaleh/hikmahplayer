import 'dart:ui';

/// The common colour vision deficiencies.
enum ColorBlindnessType {
  protanopia('Protanopia', 'Red-blind'),
  deuteranopia('Deuteranopia', 'Green-blind'),
  tritanopia('Tritanopia', 'Blue-blind'),
  achromatopsia('Achromatopsia', 'Full colour-blind');

  const ColorBlindnessType(this.label, this.description);

  final String label;
  final String description;
}

/// Builds colour-correction 4x5 RGBA matrices.
///
/// The RGB rows follow the widely-used "Daltonize" correction matrices
/// (adapted from the work by B. Dougherty / Daltonize.org), which shift hues
/// that a colour-blind viewer cannot distinguish into perceivable ranges.
/// They are approximations; UI offers a strength slider and a live preview.
class ColorBlindnessFilter {
  const ColorBlindnessFilter._();

  /// The identity matrix (no change).
  static const List<double> identity = [
    1, 0, 0, 0, 0,
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    0, 0, 0, 1, 0,
  ];

  /// Base 3x3 correction matrix for each deficiency (row-major).
  static List<double> matrixFor(ColorBlindnessType type) {
    return switch (type) {
      ColorBlindnessType.protanopia => [
          0.152286, 1.052583, -0.204868,
          0.114503, 0.786281, 0.099216,
          -0.003882, -0.048116, 1.051998,
        ],
      ColorBlindnessType.deuteranopia => [
          0.367322, 0.860646, -0.227968,
          0.280085, 0.672501, 0.047413,
          -0.011820, 0.042940, 0.968881,
        ],
      ColorBlindnessType.tritanopia => [
          1.255528, -0.076749, -0.178779,
          -0.078411, 0.930809, 0.147602,
          0.004733, 0.691367, 0.303900,
        ],
      ColorBlindnessType.achromatopsia => [
          0.2126, 0.7152, 0.0722,
          0.2126, 0.7152, 0.0722,
          0.2126, 0.7152, 0.0722,
        ],
    };
  }

  /// A 20-element RGBA filter matrix blending [type]'s correction with the
  /// identity by [strength] (`0..1`). `0` is a no-op, `1` is full correction.
  static List<double> matrix(
    ColorBlindnessType type, {
    double strength = 1.0,
  }) {
    final t = strength.clamp(0.0, 1.0);
    final correction = matrixFor(type);
    final out = List<double>.filled(20, 0);
    for (var row = 0; row < 3; row++) {
      out[row * 5] = (identity[row * 5] * (1 - t)) + correction[row * 3] * t;
      out[row * 5 + 1] = (identity[row * 5 + 1] * (1 - t)) + correction[row * 3 + 1] * t;
      out[row * 5 + 2] = (identity[row * 5 + 2] * (1 - t)) + correction[row * 3 + 2] * t;
    }
    out[18] = 1; // alpha row: 0 0 0 1 0
    return out;
  }

  /// A ready-to-use [ColorFilter] applying the correction at [strength].
  static ColorFilter colorFilter(
    ColorBlindnessType type, {
    double strength = 1.0,
  }) {
    return ColorFilter.matrix(matrix(type, strength: strength));
  }
}
