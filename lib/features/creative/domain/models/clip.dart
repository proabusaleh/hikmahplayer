import 'annotation.dart';
import 'trim_range.dart';

/// A created clip: a trimmed, optionally annotated segment exported from a
/// source [MediaItem](library) into a standalone file.
class Clip {
  /// Stable identifier.
  final String id;

  /// Identifier of the source media the clip was cut from.
  final String sourceMediaId;

  /// Title shown to the user.
  final String title;

  /// Where the media the clip was cut from lives.
  final String sourcePath;

  /// Absolute path of the exported clip file.
  final String outputPath;

  /// The exact segment captured from the source.
  final TrimRange range;

  /// Render preset used for the export.
  final Map<String, dynamic> presetJson;

  /// Overlays applied at export time.
  final List<Annotation> annotations;

  /// Free-form caption stored with the clip.
  final String? caption;

  /// User tags for grouping and search.
  final List<String> tags;

  /// Date the clip was created.
  final DateTime createdAt;

  const Clip({
    required this.id,
    required this.sourceMediaId,
    required this.title,
    required this.sourcePath,
    required this.outputPath,
    required this.range,
    this.presetJson = const {},
    this.annotations = const [],
    this.caption,
    this.tags = const [],
    required this.createdAt,
  });

  /// Duration of the exported clip.
  Duration get duration => range.duration;

  Clip copyWith({
    String? title,
    String? outputPath,
    List<Annotation>? annotations,
    String? caption,
    List<String>? tags,
    Map<String, dynamic>? presetJson,
  }) {
    return Clip(
      id: id,
      sourceMediaId: sourceMediaId,
      title: title ?? this.title,
      sourcePath: sourcePath,
      outputPath: outputPath ?? this.outputPath,
      range: range,
      presetJson: presetJson ?? this.presetJson,
      annotations: annotations ?? this.annotations,
      caption: caption ?? this.caption,
      tags: tags ?? this.tags,
      createdAt: createdAt,
    );
  }

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    if (title.toLowerCase().contains(q)) return true;
    if (caption?.toLowerCase().contains(q) ?? false) return true;
    return tags.any((t) => t.toLowerCase().contains(q));
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sourceMediaId': sourceMediaId,
        'title': title,
        'sourcePath': sourcePath,
        'outputPath': outputPath,
        'range': range.toJson(),
        'presetJson': presetJson,
        'annotations': annotations.map((a) => a.toJson()).toList(),
        'caption': caption,
        'tags': tags,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Clip.fromJson(Map<String, dynamic> json) {
    return Clip(
      id: json['id'] as String,
      sourceMediaId: json['sourceMediaId'] as String,
      title: json['title'] as String,
      sourcePath: json['sourcePath'] as String,
      outputPath: json['outputPath'] as String,
      range: TrimRange.fromJson(
          (json['range'] as Map).cast<String, dynamic>()),
      presetJson:
          (json['presetJson'] as Map<String, dynamic>? ?? const {}),
      annotations: (json['annotations'] as List<dynamic>? ?? const [])
          .map((a) => Annotation.fromJson((a as Map).cast<String, dynamic>()))
          .toList(),
      caption: json['caption'] as String?,
      tags: (json['tags'] as List<dynamic>? ?? const []).cast<String>(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) => other is Clip && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Clip(id: $id, title: $title, range: $range)';
}
