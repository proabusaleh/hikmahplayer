import 'package:rxdart/rxdart.dart' show BehaviorSubject;

enum ScanStatus { idle, scanning, cancelled }

class ScanProgressState {
  const ScanProgressState({
    this.status = ScanStatus.idle,
    this.processed = 0,
    this.total = 0,
  });

  final ScanStatus status;
  final int processed;
  final int total;

  bool get isActive => status == ScanStatus.scanning;
}

class ScanDeviceMedia {
  ScanDeviceMedia();

  final BehaviorSubject<ScanProgressState> progress =
      BehaviorSubject.seeded(const ScanProgressState());

  void emit(int processed, int total) {
    progress.add(
      ScanProgressState(status: ScanStatus.scanning, processed: processed, total: total),
    );
  }

  Future<void> startScan() async {
    throw UnimplementedError();
  }

  void cancelScan() {
    if (progress.value.isActive) {
      progress.add(const ScanProgressState(status: ScanStatus.cancelled));
    }
  }

  Future<void> dispose() => progress.close();
}
