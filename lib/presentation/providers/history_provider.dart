import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/storage/repositories/history_repository.dart';
import 'services_provider.dart';

class PlayHistory extends AsyncNotifier<List<PlayHistoryData>> {
  static const Uuid _uuid = Uuid();

  StreamSubscription<List<PlayHistoryData>>? _subscription;
  var _active = true;

  @override
  Future<List<PlayHistoryData>> build() {
    final completer = Completer<List<PlayHistoryData>>();
    final stream = ref.read(appServicesProvider).history.watchRecent();
    _subscription = stream.listen((entries) {
      if (!completer.isCompleted) {
        completer.complete(entries);
      } else if (_active) {
        state = AsyncData(entries);
      }
    }, onError: (Object error, StackTrace stackTrace) {
      if (!completer.isCompleted) {
        completer.completeError(error, stackTrace);
      }
    });
    ref.onDispose(() {
      _active = false;
      _subscription?.cancel();
    });
    return completer.future;
  }

  /// Records a playback session for [mediaId]; the mirrored stream
  /// refreshes the state.
  Future<void> record({
    required String mediaId,
    required int playedMs,
    bool completed = false,
  }) {
    return ref.read(appServicesProvider).history.record(
          id: _uuid.v4(),
          mediaId: mediaId,
          durationPlayedMs: playedMs,
          completed: completed,
        );
  }

  Future<void> clear() => ref.read(appServicesProvider).history.clearAll();

  List<PlayHistoryData> getRecent({int limit = 20}) =>
      (state.valueOrNull ?? const <PlayHistoryData>[]).take(limit).toList(
            growable: false,
          );
}

final playHistoryProvider =
    AsyncNotifierProvider<PlayHistory, List<PlayHistoryData>>(
  PlayHistory.new,
);
