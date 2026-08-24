extension StringExtensions on String {
  String get capitalize {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }

  String get orDash => isEmpty ? '-' : this;

  bool get isBlank => trim().isEmpty;
  bool get isNotBlank => !isBlank;

  String? get nullIfEmpty => isEmpty ? null : this;

  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength.clamp(0, length))}$suffix';
  }

  String get fileExtension {
    final dotIndex = lastIndexOf('.');
    if (dotIndex <= 0 || dotIndex == length - 1) return '';
    return substring(dotIndex).toLowerCase();
  }

  bool hasExtension(List<String> extensions) =>
      extensions.contains(fileExtension);
}
