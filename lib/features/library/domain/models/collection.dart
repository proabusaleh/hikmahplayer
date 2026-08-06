/// A user-defined collection of library items.
///
/// Collections support arbitrary nesting for "multi-level collections with
/// custom artwork": [parentId] points at the parent collection (or `null` for
/// a top-level collection). Membership is stored on the [LibraryItem] as
/// collection ids, keeping this model lightweight.
class LibraryCollection {
  /// Stable identifier of this collection.
  final String id;

  /// Display name of the collection.
  final String name;

  /// Optional description.
  final String? description;

  /// Parent collection id for nesting, or `null` for a top-level collection.
  final String? parentId;

  /// Custom artwork URI shown in the library UI.
  final String? artworkUri;

  /// Manual sort order within its parent.
  final int sortOrder;

  /// Whether the collection is pinned to the top of the library.
  final bool isPinned;

  /// When the collection was created.
  final DateTime createdAt;

  /// When the collection was last modified.
  final DateTime updatedAt;

  const LibraryCollection({
    required this.id,
    required this.name,
    this.description,
    this.parentId,
    this.artworkUri,
    this.sortOrder = 0,
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  LibraryCollection copyWith({
    String? id,
    String? name,
    String? description,
    bool clearDescription = false,
    String? parentId,
    bool clearParentId = false,
    String? artworkUri,
    int? sortOrder,
    bool? isPinned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LibraryCollection(
      id: id ?? this.id,
      name: name ?? this.name,
      description: clearDescription ? null : description ?? this.description,
      parentId: clearParentId ? null : parentId ?? this.parentId,
      artworkUri: artworkUri ?? this.artworkUri,
      sortOrder: sortOrder ?? this.sortOrder,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Returns a copy with [newOrder] and a bumped [updatedAt].
  LibraryCollection reorder(int newOrder) {
    return copyWith(sortOrder: newOrder, updatedAt: DateTime.now());
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'parentId': parentId,
      'artworkUri': artworkUri,
      'sortOrder': sortOrder,
      'isPinned': isPinned,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory LibraryCollection.fromJson(Map<String, dynamic> json) {
    return LibraryCollection(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      parentId: json['parentId'] as String?,
      artworkUri: json['artworkUri'] as String?,
      sortOrder: json['sortOrder'] as int? ?? 0,
      isPinned: json['isPinned'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is LibraryCollection && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'LibraryCollection(id: $id, name: $name, parent: $parentId)';
}
