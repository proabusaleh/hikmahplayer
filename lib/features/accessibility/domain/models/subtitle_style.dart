import 'dart:math' as math;

/// Horizontal alignment of rendered subtitles.
enum SubtitleAlign { left, center, right }

/// A fully customisable subtitle rendering style.
///
/// Mirrors what a renderer needs (colour, size, outline, background, shadow,
/// position) without depending on any specific subtitle package. All colours
/// are ARGB `int`s. [verticalPosition] is a `0..1` fraction of the frame
/// height measured from the bottom.
class SubtitleStyle {
  final String id;

  /// Human readable name (also used by presets).
  final String label;

  /// Font size in px (scaled by [sizeScale] at render time).
  final double fontSize;

  /// Relative scale multiplier (e.g. `1.5` for large print).
  final double sizeScale;

  /// Optional font family override.
  final String? fontFamily;

  final bool bold;
  final bool italic;

  /// Text colour (ARGB).
  final int color;

  /// Background box colour (ARGB). `null` renders no background box.
  final int? backgroundColor;

  /// Opacity of the background box (`0..1`).
  final double backgroundOpacity;

  /// Outline colour (ARGB). Ignored when [outlineWidth] is `0`.
  final int outlineColor;

  /// Outline thickness in px.
  final double outlineWidth;

  /// Whether to draw a drop shadow.
  final bool shadow;

  /// Letter spacing in px (positive values aid dyslexia).
  final double letterSpacing;

  final SubtitleAlign align;

  /// `0..1` position from the bottom of the frame (`0` = bottom edge).
  final double verticalPosition;

  const SubtitleStyle({
    required this.id,
    required this.label,
    this.fontSize = 24,
    this.sizeScale = 1.0,
    this.fontFamily,
    this.bold = false,
    this.italic = false,
    this.color = 0xFFFFFFFF,
    this.backgroundColor,
    this.backgroundOpacity = 1.0,
    this.outlineColor = 0xFF000000,
    this.outlineWidth = 0,
    this.shadow = false,
    this.letterSpacing = 0,
    this.align = SubtitleAlign.center,
    this.verticalPosition = 0.05,
  });

  /// The background colour composited over black at [backgroundOpacity].
  /// Returns `null` when no background is set.
  int? get effectiveBackgroundColor {
    final bg = backgroundColor;
    if (bg == null) return null;
    final alpha = ((bg >> 24) & 0xFF) * backgroundOpacity;
    if (alpha <= 0) return null;
    double blend(int channel) =>
        (channel * (alpha / 255.0)).roundToDouble();
    return 0xFF000000 |
        (blend((bg >> 16) & 0xFF).toInt() << 16) |
        (blend((bg >> 8) & 0xFF).toInt() << 8) |
        blend(bg & 0xFF).toInt();
  }

  /// Colour the text is drawn against for contrast purposes: the background
  /// box when set, otherwise the outline when thick enough, otherwise black.
  int get contrastBackground {
    final bg = effectiveBackgroundColor;
    if (bg != null) return bg;
    if (outlineWidth >= 1) return outlineColor;
    return 0xFF000000;
  }

  /// WCAG contrast ratio of the text against [contrastBackground].
  double get contrastRatio =>
      SubtitleStyle.contrastRatioBetween(color, contrastBackground);

  /// WCAG relative luminance of an ARGB colour (`0..1`).
  static double relativeLuminance(int argb) {
    double channel(double c) =>
        c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4) as double;
    final r = ((argb >> 16) & 0xFF) / 255.0;
    final g = ((argb >> 8) & 0xFF) / 255.0;
    final b = (argb & 0xFF) / 255.0;
    return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b);
  }

  /// WCAG contrast ratio between two ARGB colours (>= 1.0).
  static double contrastRatioBetween(int fg, int bg) {
    final l1 = relativeLuminance(fg);
    final l2 = relativeLuminance(bg);
    final hi = math.max(l1, l2);
    final lo = math.min(l1, l2);
    return (hi + 0.05) / (lo + 0.05);
  }

  /// Returns the text size in px combining [fontSize] and [sizeScale].
  double get effectiveFontSize => fontSize * sizeScale;

  SubtitleStyle copyWith({
    String? label,
    double? fontSize,
    double? sizeScale,
    String? fontFamily,
    bool? bold,
    bool? italic,
    int? color,
    int? backgroundColor,
    double? backgroundOpacity,
    int? outlineColor,
    double? outlineWidth,
    bool? shadow,
    double? letterSpacing,
    SubtitleAlign? align,
    double? verticalPosition,
    bool clearBackground = false,
  }) {
    return SubtitleStyle(
      id: id,
      label: label ?? this.label,
      fontSize: fontSize ?? this.fontSize,
      sizeScale: sizeScale ?? this.sizeScale,
      fontFamily: fontFamily ?? this.fontFamily,
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      color: color ?? this.color,
      backgroundColor:
          clearBackground ? null : backgroundColor ?? this.backgroundColor,
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
      outlineColor: outlineColor ?? this.outlineColor,
      outlineWidth: outlineWidth ?? this.outlineWidth,
      shadow: shadow ?? this.shadow,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      align: align ?? this.align,
      verticalPosition: verticalPosition ?? this.verticalPosition,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'fontSize': fontSize,
        'sizeScale': sizeScale,
        'fontFamily': fontFamily,
        'bold': bold,
        'italic': italic,
        'color': color,
        'backgroundColor': backgroundColor,
        'backgroundOpacity': backgroundOpacity,
        'outlineColor': outlineColor,
        'outlineWidth': outlineWidth,
        'shadow': shadow,
        'letterSpacing': letterSpacing,
        'align': align.name,
        'verticalPosition': verticalPosition,
      };

  factory SubtitleStyle.fromJson(Map<String, dynamic> json) {
    return SubtitleStyle(
      id: json['id'] as String,
      label: json['label'] as String,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 24,
      sizeScale: (json['sizeScale'] as num?)?.toDouble() ?? 1.0,
      fontFamily: json['fontFamily'] as String?,
      bold: json['bold'] as bool? ?? false,
      italic: json['italic'] as bool? ?? false,
      color: json['color'] as int? ?? 0xFFFFFFFF,
      backgroundColor: json['backgroundColor'] as int?,
      backgroundOpacity: (json['backgroundOpacity'] as num?)?.toDouble() ?? 1.0,
      outlineColor: json['outlineColor'] as int? ?? 0xFF000000,
      outlineWidth: (json['outlineWidth'] as num?)?.toDouble() ?? 0,
      shadow: json['shadow'] as bool? ?? false,
      letterSpacing: (json['letterSpacing'] as num?)?.toDouble() ?? 0,
      align: SubtitleAlign.values.asNameMap()[json['align']] ??
          SubtitleAlign.center,
      verticalPosition: (json['verticalPosition'] as num?)?.toDouble() ?? 0.05,
    );
  }

  @override
  String toString() => 'SubtitleStyle($id, ${effectiveFontSize}px, '
      'contrast ${contrastRatio.toStringAsFixed(1)}:1)';
}
