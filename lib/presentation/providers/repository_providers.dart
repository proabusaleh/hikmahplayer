import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/app_services.dart';
import '../../core/services/library_service.dart';
import '../../features/player/domain/models/media_item.dart';
import '../../features/player/presentation/providers/player_state_provider.dart';

final appServicesProvider = Provider<AppServices>((ref) {
  throw UnimplementedError('Must be overridden at the top level');
});

final libraryServiceProvider = Provider<LibraryService>((ref) {
  return ref.watch(appServicesProvider).library;
});

final playerProvider = Provider<_PlayerActions>((ref) {
  final stateNotifier = ref.read(playerStateProvider.notifier);
  return _PlayerActions(stateNotifier);
});

class _PlayerActions {
  final PlayerStateNotifier _notifier;
  _PlayerActions(this._notifier);

  Future<void> playMedia(MediaItem item) => _notifier.playMedia(item);
  Future<void> playQueue(List<MediaItem> items, {int startIndex = 0}) =>
      _notifier.playQueue(items, startIndex: startIndex);
  Future<void> addToQueue(MediaItem item) => _notifier.addToQueue(item);
  Future<void> playNext(MediaItem item) async {
    await _notifier.addToQueue(item);
  }
  Future<void> toggleShuffle() => _notifier.toggleShuffle();
}
