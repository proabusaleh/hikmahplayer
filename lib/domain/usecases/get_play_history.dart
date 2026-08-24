import '../repositories/history_repository.dart';

class GetPlayHistory {
  const GetPlayHistory(this._repository);

  final HistoryRepository _repository;

  Future<dynamic> call({int limit = 50}) => _repository.getRecent(limit: limit);
}
