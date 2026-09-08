import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationIds {
  static const music = 1001;
  static const video = 1002;
  static const download = 2001;
  static const transfer = 2002;
  static const downloadComplete = 2100;
  static const transferComplete = 2200;
}

class NotificationChannels {
  static const music = 'hikmah_music';
  static const video = 'hikmah_video';
  static const download = 'hikmah_download';
  static const transfer = 'hikmah_transfer';
}

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init({
    void Function(NotificationResponse)? onTap,
  }) async {
    if (_ready) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: onTap,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    await _createChannels();
    await _requestPermission();
    _ready = true;
  }

  Future<void> _requestPermission() async {
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
    }
  }

  Future<void> _createChannels() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    await android.createNotificationChannel(const AndroidNotificationChannel(
      NotificationChannels.music,
      'Music Playback',
      description: 'Controls for currently playing music',
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
      showBadge: false,
    ));

    await android.createNotificationChannel(const AndroidNotificationChannel(
      NotificationChannels.video,
      'Video Playback',
      description: 'Video playback status',
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
    ));

    await android.createNotificationChannel(const AndroidNotificationChannel(
      NotificationChannels.download,
      'Downloads',
      description: 'Download progress and completion',
      importance: Importance.defaultImportance,
      playSound: true,
    ));

    await android.createNotificationChannel(const AndroidNotificationChannel(
      NotificationChannels.transfer,
      'File Transfer',
      description: 'Wi‑Fi / nearby transfer progress',
      importance: Importance.defaultImportance,
    ));
  }

  Future<void> showDownloadProgress({
    required String taskId,
    required String fileName,
    required int progress,
    required int max,
  }) async {
    final android = AndroidNotificationDetails(
      NotificationChannels.download,
      'Downloads',
      channelDescription: 'Download progress',
      importance: Importance.low,
      priority: Priority.low,
      onlyAlertOnce: true,
      showProgress: true,
      maxProgress: max,
      progress: progress,
      ongoing: progress < max,
      autoCancel: false,
      category: AndroidNotificationCategory.progress,
      icon: '@mipmap/ic_launcher',
    );

    await _plugin.show(
      NotificationIds.download + taskId.hashCode.abs() % 100,
      'Downloading',
      '$fileName • $progress%',
      NotificationDetails(android: android),
      payload: 'download:$taskId',
    );
  }

  Future<void> showDownloadComplete({
    required String taskId,
    required String fileName,
    String? path,
  }) async {
    final android = AndroidNotificationDetails(
      NotificationChannels.download,
      'Downloads',
      channelDescription: 'Download complete',
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.status,
      styleInformation: BigTextStyleInformation(
        path != null ? 'Saved to $path' : 'Download finished',
        contentTitle: 'Download complete',
        summaryText: fileName,
      ),
    );

    await _plugin.show(
      NotificationIds.downloadComplete + taskId.hashCode.abs() % 50,
      'Download complete',
      fileName,
      NotificationDetails(android: android),
      payload: 'download_done:$taskId',
    );

    await _plugin.cancel(NotificationIds.download + taskId.hashCode.abs() % 100);
  }

  Future<void> showDownloadFailed({
    required String taskId,
    required String fileName,
    String? error,
  }) async {
    await _plugin.show(
      NotificationIds.downloadComplete + taskId.hashCode.abs() % 50,
      'Download failed',
      error ?? fileName,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationChannels.download,
          'Downloads',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: 'download_fail:$taskId',
    );
  }

  Future<void> showTransferProgress({
    required String sessionId,
    required String title,
    required int progress,
    required int max,
    String? subtitle,
  }) async {
    final android = AndroidNotificationDetails(
      NotificationChannels.transfer,
      'File Transfer',
      channelDescription: 'Transfer progress',
      importance: Importance.low,
      priority: Priority.low,
      onlyAlertOnce: true,
      showProgress: true,
      maxProgress: max,
      progress: progress,
      ongoing: progress < max,
      autoCancel: false,
      category: AndroidNotificationCategory.progress,
    );

    await _plugin.show(
      NotificationIds.transfer + sessionId.hashCode.abs() % 100,
      title,
      subtitle ?? '$progress%',
      NotificationDetails(android: android),
      payload: 'transfer:$sessionId',
    );
  }

  Future<void> showTransferComplete({
    required String sessionId,
    required String title,
    required String message,
  }) async {
    await _plugin.show(
      NotificationIds.transferComplete + sessionId.hashCode.abs() % 50,
      title,
      message,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationChannels.transfer,
          'File Transfer',
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.status,
        ),
      ),
      payload: 'transfer_done:$sessionId',
    );
    await _plugin.cancel(NotificationIds.transfer + sessionId.hashCode.abs() % 100);
  }

  Future<void> showVideoStatus({
    required String title,
    required bool isPlaying,
    String? positionLabel,
  }) async {
    final android = AndroidNotificationDetails(
      NotificationChannels.video,
      'Video Playback',
      channelDescription: 'Video playback',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: isPlaying,
      autoCancel: false,
      category: AndroidNotificationCategory.transport,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          isPlaying ? 'video_pause' : 'video_play',
          isPlaying ? 'Pause' : 'Play',
          showsUserInterface: false,
        ),
        const AndroidNotificationAction('video_stop', 'Stop'),
      ],
    );

    await _plugin.show(
      NotificationIds.video,
      title,
      isPlaying ? (positionLabel ?? 'Playing') : 'Paused',
      NotificationDetails(android: android),
      payload: 'video',
    );
  }

  Future<void> cancelVideo() => _plugin.cancel(NotificationIds.video);
  Future<void> cancelAll() => _plugin.cancelAll();

  Future<void> cancelDownload(String taskId) async {
    await _plugin.cancel(NotificationIds.download + taskId.hashCode.abs() % 100);
  }
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  debugPrint('BG notification: ${response.actionId} ${response.payload}');
}
