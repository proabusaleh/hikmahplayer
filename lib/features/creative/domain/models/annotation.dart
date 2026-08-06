/// Visual annotations that can be layered onto a clip before export.
enum AnnotationType { arrow, highlight, text, sticker, emoji, freehand }

/// How an [Annotation] is drawn over the frame.
enum AnnotationStyle { solid, outline, filled }

/// A timed overlay placed on top of the video during clip export.
///
/// Instances are render hints: the actual drawing happens in the export UI,
/// but the model carries everything needed to rebuild the overlay, including a
/// JSON payload of renderer-specific data (points, text, colour, etc.).
class Annotation {
  /// Stable identifier.
  final String id;

  /// What kind of annotation this is.
  final AnnotationType type;

  /// Time range during which the annotation is visible.
  final Duration start;
  final Duration end;

  /// Normalised position `(0..1)` within the frame, e.g. `{x: 0.5, y: 0.25}`.
  final Map<String, double> position;

  /// Renderer payload (points for freehand/arrow, text for text/emoji, ...).
  final Map<String, dynamic> data;

  /// Drawing style.
  final AnnotationStyle style;

  /// ARGB colour.
  final int color;

  const Annotation({
    required this.id,
    required this.type,
    required this.start,
    required this.end,
    this.position = const {'x': 0.5, 'y': 0.5},
    this.data = const {},
    this.style = AnnotationStyle.solid,
    this.color = 0xFFFFFFFF,
  });

  bool isVisibleAt(Duration position) =>
      position >= start && position <= end;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'start': start.inMilliseconds,
        'end': end.inMilliseconds,
        'position': position,
        'data': data,
        'style': style.name,
        'color': color,
      };

  factory Annotation.fromJson(Map<String, dynamic> json) {
    return Annotation(
      id: json['id'] as String,
      type: AnnotationType.values.asNameMap()[json['type']] ??
          AnnotationType.text,
      start: Duration(milliseconds: json['start'] as int),
      end: Duration(milliseconds: json['end'] as int),
      position: (json['position'] as Map<String, dynamic>? ?? const {})
          .cast<String, double>(),
      data: json['data'] as Map<String, dynamic>? ?? const {},
      style: AnnotationStyle.values.asNameMap()[json['style']] ??
          AnnotationStyle.solid,
      color: json['color'] as int? ?? 0xFFFFFFFF,
    );
  }

  @override
  bool operator ==(Object other) => other is Annotation && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Annotation($type, ${start.inMilliseconds}ms-'
      '${end.inMilliseconds}ms)';
}
