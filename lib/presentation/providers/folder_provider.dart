import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/repositories/folder_repository.dart';
import 'services_provider.dart';

class FolderList extends AsyncNotifier<List<Folder>> {
  StreamSubscription<List<Folder>>? _subscription;
  var _active = true;

  @override
  Future<List<Folder>> build() {
    final completer = Completer<List<Folder>>();
    final stream = ref.read(appServicesProvider).folders.watchAll();
    _subscription = stream.listen((folders) {
      if (!completer.isCompleted) {
        completer.complete(folders);
      } else if (_active) {
        state = AsyncData(folders);
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

  void refresh() => ref.invalidateSelf();
}

final folderListProvider =
    AsyncNotifierProvider<FolderList, List<Folder>>(FolderList.new);
