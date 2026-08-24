import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/play_history_entry.dart';

class PlayHistory extends AsyncNotifier<List<PlayHistoryEntry>> {
  @override
  Future<List<PlayHistoryEntry>> build() async => const [];

  Future<void> record(PlayHistoryEntry entry) async {
    final current = state.valueOrNull ?? const <PlayHistoryEntry>[];
    state = AsyncData(<PlayHistoryEntry>[entry, ...current]);
  }

  Future<void> clear() async {
    state = const AsyncData(<PlayHistoryEntry>[]);
  }

  List<PlayHistoryEntry> getRecent({int limit = 20}) {
    final entries = state.valueOrNull ?? const <PlayHistoryEntry>[];
    return entries.take(limit).toList();
  }
}

final playHistoryProvider =
    AsyncNotifierProvider<PlayHistory, List<PlayHistoryEntry>>(
  PlayHistory.new,
);
