/// An encrypted media container holding vault content.
class EncryptedContainer {
  final String id;
  final String mediaId;

  /// Encryption scheme label (e.g. `hmac-sha256-stream`).
  final String algorithm;

  final DateTime createdAt;

  /// Whether the container integrity check passes.
  final bool integrityValid;

  const EncryptedContainer({
    required this.id,
    required this.mediaId,
    this.algorithm = 'hmac-sha256-stream',
    required this.createdAt,
    this.integrityValid = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'mediaId': mediaId,
        'algorithm': algorithm,
        'createdAt': createdAt.toIso8601String(),
        'integrityValid': integrityValid,
      };

  factory EncryptedContainer.fromJson(Map<String, dynamic> json) {
    return EncryptedContainer(
      id: json['id'] as String,
      mediaId: json['mediaId'] as String,
      algorithm: json['algorithm'] as String? ?? 'hmac-sha256-stream',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      integrityValid: json['integrityValid'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is EncryptedContainer && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
