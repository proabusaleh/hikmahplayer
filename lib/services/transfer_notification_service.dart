import 'notification_service.dart';

class TransferNotificationService {
  TransferNotificationService._();
  static final instance = TransferNotificationService._();

  Future<void> progress({
    required String sessionId,
    required String peerName,
    required int sentBytes,
    required int totalBytes,
    bool incoming = false,
  }) async {
    final p = totalBytes == 0 ? 0 : ((sentBytes / totalBytes) * 100).toInt();
    await NotificationService.instance.showTransferProgress(
      sessionId: sessionId,
      title: incoming ? 'Receiving from $peerName' : 'Sending to $peerName',
      progress: p,
      max: 100,
      subtitle: '$p% • ${_fmt(sentBytes)} / ${_fmt(totalBytes)}',
    );
  }

  Future<void> complete({
    required String sessionId,
    required String peerName,
    required int fileCount,
    bool incoming = false,
  }) async {
    await NotificationService.instance.showTransferComplete(
      sessionId: sessionId,
      title: incoming ? 'Transfer received' : 'Transfer sent',
      message: '$fileCount file(s) ${incoming ? 'from' : 'to'} $peerName',
    );
  }

  String _fmt(int b) {
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(0)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
