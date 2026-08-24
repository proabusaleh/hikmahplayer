import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  const Failure({this.message, this.code});

  final String? message;
  final String? code;

  @override
  List<Object?> get props => [message, code];
}

class DatabaseFailure extends Failure {
  const DatabaseFailure({super.message, super.code});
}

class CacheFailure extends Failure {
  const CacheFailure({super.message, super.code});
}

class FileSystemFailure extends Failure {
  const FileSystemFailure({super.message, super.code});
}

class PermissionFailure extends Failure {
  const PermissionFailure({super.message, super.code});
}

class PlaybackFailure extends Failure {
  const PlaybackFailure({super.message, super.code});
}

class MetadataFailure extends Failure {
  const MetadataFailure({super.message, super.code});
}

class ScanFailure extends Failure {
  const ScanFailure({super.message, super.code});
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure({super.message, super.code});
}
