import '../repositories/history_repository.dart';

class UpdatePlaybackPosition {
  const UpdatePlaybackPosition(this._repository);

  final HistoryRepository _repository;

  Future<void> call({
    required String mediaId,
    required Duration position,
    Duration duration = Duration.zero,
  }) =>
      _repository.recordEntry(
        mediaId: mediaId,
        position: position,
        duration: duration,
      );
}
