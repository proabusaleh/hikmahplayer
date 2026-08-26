import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';

import 'app.dart';
import 'core/di/app_services.dart';
import 'core/utils/app_logger.dart';
import 'presentation/providers/repository_providers.dart';
import 'services/notification_service.dart';
import 'services/player_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await Hive.initFlutter();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final box = await Hive.openBox('hikmah_prefs');
  final isFirstRun = !(box.get('has_launched', defaultValue: false) as bool);

  final services = AppServices();

  // ─── Initialize background audio service ───
  final playerService = PlayerService();
  await NotificationService.init(playerService);
  logInfo('App initialized — background audio ready');

  runApp(
    ProviderScope(
      overrides: [
        appServicesProvider.overrideWithValue(services),
      ],
      child: HikmahApp(services: services, isFirstRun: isFirstRun),
    ),
  );
}
