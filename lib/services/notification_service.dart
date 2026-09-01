import 'package:audio_service/audio_service.dart';

import '../core/utils/app_logger.dart';
import 'background_audio_service.dart';
import 'player_service.dart';

/// Manages initialization of the background audio service.
///
/// Call [NotificationService.init] once at app startup, before
/// `runApp()`, so the system media session is available as soon as
/// the first media item loads.
class NotificationService {
  static BackgroundAudioService? _audioHandler;

  /// Initialize audio_service and return the handler.
  static Future<BackgroundAudioService> init(
    PlayerService playerService,
  ) async {
    _audioHandler = await AudioService.init(
      builder: () => BackgroundAudioService(playerService),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.hikmahplayer.audio',
        androidNotificationChannelName: 'Hikmah Player',
        androidNotificationChannelDescription: 'Media playback controls',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
        androidNotificationIcon: 'drawable/ic_notification',
        androidShowNotificationBadge: true,
        preloadArtwork: false,
        artDownscaleWidth: 300,
        artDownscaleHeight: 300,
        fastForwardInterval: Duration(seconds: 10),
        rewindInterval: Duration(seconds: 10),
      ),
    );

    logInfo('NotificationService initialized');
    return _audioHandler!;
  }

  /// The active audio handler, or null before [init] completes.
  static BackgroundAudioService? get handler => _audioHandler;
}
