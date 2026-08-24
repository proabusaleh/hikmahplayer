import 'package:flutter_riverpod/flutter_riverpod.dart';

sealed class ScanState {
  const ScanState();
}

class ScanIdle extends ScanState {
  const ScanIdle();
}

class ScanInProgress extends ScanState {
  const ScanInProgress({required this.processed, required this.total});
  final int processed;
  final int total;

  double get progressValue => total == 0 ? 0 : processed / total;
}

class ScanCompleted extends ScanState {
  const ScanCompleted({required this.foundCount});
  final int foundCount;
}

class ScanError extends ScanState {
  const ScanError({required this.message});
  final String message;
}

class MediaScannerController extends Notifier<ScanState> {
  @override
  ScanState build() => const ScanIdle();

  void startScan() => throw UnimplementedError();

  void cancelScan() {
    state = const ScanIdle();
  }
}

final scannerProvider =
    NotifierProvider<MediaScannerController, ScanState>(
  MediaScannerController.new,
);
