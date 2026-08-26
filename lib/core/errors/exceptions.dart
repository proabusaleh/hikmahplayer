sealed class AppException implements Exception {
  const AppException([this.message, this.code]);

  final String? message;
  final String? code;

  @override
  String toString() =>
      '$runtimeType(code: $code, message: $message)';
}

class DatabaseException extends AppException {
  const DatabaseException([super.message, super.code]);
}

class FileSystemException extends AppException {
  const FileSystemException([super.message, super.code]);
}

class PermissionDeniedException extends AppException {
  const PermissionDeniedException([super.message, super.code]);
}

class MediaNotFoundException extends AppException {
  const MediaNotFoundException([super.message, super.code]);
}

class PlaybackException extends AppException {
  const PlaybackException([super.message, super.code]);
}

class ScanCancelledException extends AppException {
  const ScanCancelledException([super.message, super.code]);
}
