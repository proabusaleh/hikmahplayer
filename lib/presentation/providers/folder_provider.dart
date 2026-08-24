import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/folder.dart';

class FolderList extends AsyncNotifier<List<Folder>> {
  @override
  Future<List<Folder>> build() async => const [];

  void refresh() => ref.invalidateSelf();
}

final folderListProvider =
    AsyncNotifierProvider<FolderList, List<Folder>>(FolderList.new);
