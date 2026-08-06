import 'clip.dart';

/// A named, shareable grouping of [Clip]s.
///
/// Mirrors the library collections model: a collection can hold clips directly
/// and can nest other collections. Clip ids are referenced so a clip can live
/// in several collections without duplication.
class ClipCollection {
  /// Stable identifier.
  final String id;

  /// Display name.
  final String name;

  /// Optional description.
  final String? description;

  /// Ids of clips directly held in this collection.
  final List<String> clipIds;

  /// Ids of nested collections.
  final List<String> childCollectionIds;

  /// Whether this is a system collection (e.g. "Favourites") that cannot be
  /// renamed or deleted.
  final bool isSystem;

  final DateTime createdAt;

  const ClipCollection({
    required this.id,
    required this.name,
    this.description,
    this.clipIds = const [],
    this.childCollectionIds = const [],
    this.isSystem = false,
    required this.createdAt,
  });

  ClipCollection copyWith({
    String? name,
    String? description,
    List<String>? clipIds,
    List<String>? childCollectionIds,
    bool? isSystem,
  }) {
    return ClipCollection(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      clipIds: clipIds ?? this.clipIds,
      childCollectionIds: childCollectionIds ?? this.childCollectionIds,
      isSystem: isSystem ?? this.isSystem,
      createdAt: createdAt,
    );
  }

  ClipCollection withClip(String clipId) {
    if (clipIds.contains(clipId)) return this;
    return copyWith(clipIds: [...clipIds, clipId]);
  }

  ClipCollection withoutClip(String clipId) {
    if (!clipIds.contains(clipId)) return this;
    return copyWith(clipIds: clipIds.where((id) => id != clipId).toList());
  }

  bool contains(String clipId) => clipIds.contains(clipId);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'clipIds': clipIds,
        'childCollectionIds': childCollectionIds,
        'isSystem': isSystem,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ClipCollection.fromJson(Map<String, dynamic> json) {
    return ClipCollection(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      clipIds:
          (json['clipIds'] as List<dynamic>? ?? const []).cast<String>(),
      childCollectionIds: (json['childCollectionIds'] as List<dynamic>? ??
              const [])
          .cast<String>(),
      isSystem: json['isSystem'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ClipCollection && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ClipCollection(id: $id, name: $name, '
      'clips: ${clipIds.length}, children: ${childCollectionIds.length})';
}
