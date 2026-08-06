/// A user-defined tag that can be attached to library items.
///
/// Tags power custom organization and smart playlists ("custom tags, ratings
/// and collections"). A tag is intentionally light: a name and optional color
/// so the UI can tint chips and filters.
class MediaTag {
  /// Stable identifier of this tag.
  final String id;

  /// Unique, human-readable tag name (e.g. "To Watch", "Kids", "Lecture").
  final String name;

  /// ARGB color used to render the tag in the UI.
  final int colorValue;

  /// Optional description shown in the tag manager.
  final String? description;

  /// When the tag was created.
  final DateTime createdAt;

  const MediaTag({
    required this.id,
    required this.name,
    this.colorValue = 0xFF8E97FD,
    this.description,
    required this.createdAt,
  });

  MediaTag copyWith({
    String? id,
    String? name,
    int? colorValue,
    String? description,
    DateTime? createdAt,
  }) {
    return MediaTag(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'colorValue': colorValue,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MediaTag.fromJson(Map<String, dynamic> json) {
    return MediaTag(
      id: json['id'] as String,
      name: json['name'] as String,
      colorValue: json['colorValue'] as int? ?? 0xFF8E97FD,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MediaTag && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'MediaTag(id: $id, name: $name)';
}
