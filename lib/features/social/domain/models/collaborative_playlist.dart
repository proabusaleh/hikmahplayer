class CollaborativePlaylist {
  final String id;
  final String name;
  final String creatorId;
  final String? description;
  final List<CollaborativePlaylistEntry> entries;
  final Set<String> collaboratorIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CollaborativePlaylist({
    required this.id,
    required this.name,
    required this.creatorId,
    this.description,
    this.entries = const [],
    this.collaboratorIds = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  int get itemCount => entries.length;

  CollaborativePlaylist copyWith({
    String? name,
    String? description,
    List<CollaborativePlaylistEntry>? entries,
    Set<String>? collaboratorIds,
  }) =>
      CollaborativePlaylist(
        id: id,
        name: name ?? this.name,
        creatorId: creatorId,
        description: description ?? this.description,
        entries: entries ?? this.entries,
        collaboratorIds: collaboratorIds ?? this.collaboratorIds,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'creatorId': creatorId,
        'description': description,
        'entries': entries.map((e) => e.toJson()).toList(),
        'collaboratorIds': collaboratorIds.toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory CollaborativePlaylist.fromJson(Map<String, dynamic> json) =>
      CollaborativePlaylist(
        id: json['id'] as String,
        name: json['name'] as String,
        creatorId: json['creatorId'] as String,
        description: json['description'] as String?,
        entries: (json['entries'] as List<dynamic>? ?? [])
            .map((e) => CollaborativePlaylistEntry.fromJson(
                e as Map<String, dynamic>))
            .toList(),
        collaboratorIds:
            (json['collaboratorIds'] as List<dynamic>? ?? []).cast<String>().toSet(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

class CollaborativePlaylistEntry {
  final String mediaId;
  final String addedBy;
  final DateTime addedAt;

  const CollaborativePlaylistEntry({
    required this.mediaId,
    required this.addedBy,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() => {
        'mediaId': mediaId,
        'addedBy': addedBy,
        'addedAt': addedAt.toIso8601String(),
      };

  factory CollaborativePlaylistEntry.fromJson(Map<String, dynamic> json) =>
      CollaborativePlaylistEntry(
        mediaId: json['mediaId'] as String,
        addedBy: json['addedBy'] as String,
        addedAt: DateTime.parse(json['addedAt'] as String),
      );
}
