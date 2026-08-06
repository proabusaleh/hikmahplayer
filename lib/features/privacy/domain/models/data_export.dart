/// Result of an encrypted data export.
class DataExportResult {
  /// Base64-encoded encrypted blob (`MAC || nonce || ciphertext`).
  final String blob;

  /// SHA-256 hex of the plaintext payload for integrity reporting.
  final String integrityHash;

  final DateTime exportedAt;

  /// Number of data items included.
  final int itemCount;

  const DataExportResult({
    required this.blob,
    required this.integrityHash,
    required this.exportedAt,
    required this.itemCount,
  });

  Map<String, dynamic> toJson() => {
        'blob': blob,
        'integrityHash': integrityHash,
        'exportedAt': exportedAt.toIso8601String(),
        'itemCount': itemCount,
      };
}

/// Result of an encrypted data import.
class DataImportResult {
  final bool success;
  final int itemCount;
  final String? error;
  final DateTime? importedAt;

  const DataImportResult({
    required this.success,
    this.itemCount = 0,
    this.error,
    this.importedAt,
  });

  factory DataImportResult.failure(String error) =>
      DataImportResult(success: false, error: error);
}
