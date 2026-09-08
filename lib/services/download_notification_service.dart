import 'notification_service.dart';

class DownloadTask {
  final String id;
  final String fileName;
  int progress;
  String? savePath;
  bool failed;

  DownloadTask({
    required this.id,
    required this.fileName,
    this.progress = 0,
    this.savePath,
    this.failed = false,
  });
}

class DownloadNotificationService {
  DownloadNotificationService._();
  static final instance = DownloadNotificationService._();

  final Map<String, DownloadTask> _tasks = {};

  Future<void> start(String id, String fileName) async {
    _tasks[id] = DownloadTask(id: id, fileName: fileName);
    await NotificationService.instance.showDownloadProgress(
      taskId: id,
      fileName: fileName,
      progress: 0,
      max: 100,
    );
  }

  Future<void> update(String id, int progress) async {
    final t = _tasks[id];
    if (t == null) return;
    t.progress = progress.clamp(0, 100);
    if (progress % 2 == 0 || progress >= 100) {
      await NotificationService.instance.showDownloadProgress(
        taskId: id,
        fileName: t.fileName,
        progress: t.progress,
        max: 100,
      );
    }
  }

  Future<void> complete(String id, {String? path}) async {
    final t = _tasks[id];
    if (t == null) return;
    t.savePath = path;
    await NotificationService.instance.showDownloadComplete(
      taskId: id,
      fileName: t.fileName,
      path: path,
    );
    _tasks.remove(id);
  }

  Future<void> fail(String id, String error) async {
    final t = _tasks[id];
    if (t == null) return;
    t.failed = true;
    await NotificationService.instance.showDownloadFailed(
      taskId: id,
      fileName: t.fileName,
      error: error,
    );
    _tasks.remove(id);
  }
}
