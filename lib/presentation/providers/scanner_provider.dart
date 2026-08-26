import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/library_service.dart';
import 'services_provider.dart';

sealed class ScanState {
  const ScanState();
}

class ScanIdle extends ScanState {
  const ScanIdle();
}

/// [processed] of [total] folders scanned.
class ScanInProgress extends ScanState {
  const ScanInProgress({required this.processed, required this.total});

  final int processed;
  final int total;

  double get progressValue => total == 0 ? 0 : processed / total;
}

class ScanCompleted extends ScanState {
  const ScanCompleted({required this.foundCount});

  /// Media files discovered across all scanned folders.
  final int foundCount;
}

class ScanError extends ScanState {
  const ScanError({required this.message});

  final String message;
}

/// Drives folder scans through the shared [LibraryService].
///
/// Progress is reported per folder (the service scans one folder at a
/// time); cancellation takes effect between folders, the in-flight folder
/// always finishes.
class MediaScannerController extends Notifier<ScanState> {
  bool _running = false;
  bool _cancelled = false;

  @override
  ScanState build() => const ScanIdle();

  Future<void> startScan() async {
    if (_running) return;
    final library = ref.read(appServicesProvider).library;
    final folders = [
      for (final folder in library.folders)
        if (folder.enabled) folder,
    ];

    _running = true;
    _cancelled = false;
    try {
      if (folders.isEmpty) {
        state = const ScanCompleted(foundCount: 0);
        return;
      }
      state = ScanInProgress(processed: 0, total: folders.length);
      var discovered = 0;
      for (var i = 0; i < folders.length; i++) {
        if (_cancelled) return;
        try {
          final result = await library.scanFolder(folders[i].id);
          discovered += result.discovered;
        } catch (error) {
          state = ScanError(message: error.toString());
          return;
        }
        state = ScanInProgress(processed: i + 1, total: folders.length);
      }
      state = ScanCompleted(foundCount: discovered);
    } finally {
      _running = false;
    }
  }

  void cancelScan() {
    _cancelled = true;
    state = const ScanIdle();
  }
}

final scannerProvider =
    NotifierProvider<MediaScannerController, ScanState>(
  MediaScannerController.new,
);
