class FileSizeFormatter {
  const FileSizeFormatter._();

  static const double _bytesPerKb = 1024;
  static const double _bytesPerMb = _bytesPerKb * 1024;
  static const double _bytesPerGb = _bytesPerMb * 1024;

  static String format(int bytes) {
    if (bytes < 0) return '';
    if (bytes < _bytesPerKb) return '$bytes B';
    if (bytes < _bytesPerMb) {
      return '${_trim(bytes / _bytesPerKb)} KB';
    }
    if (bytes < _bytesPerGb) {
      return '${_trim(bytes / _bytesPerMb)} MB';
    }
    return '${_trim(bytes / _bytesPerGb)} GB';
  }

  static String _trim(double value) {
    final fixed = value.toStringAsFixed(1);
    return fixed.endsWith('.0') ? fixed.substring(0, fixed.length - 2) : fixed;
  }
}
