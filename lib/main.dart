import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';

import 'app.dart';
import 'core/di/app_services.dart';
import 'core/router/app_router.dart';
import 'core/storage/storage_locations.dart';
import 'presentation/providers/services_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await Hive.initFlutter();
  await StorageLocations.clearTemp();

  // Phones start portrait; the player screens switch to landscape
  // (and restore this) via SystemChrome while active.
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
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final services = await AppServices.create();
  unawaited(services.theme.refreshDynamicSeed());
  final router = createAppRouter(prefs: services.prefs);
  runApp(
    ProviderScope(
      overrides: [appServicesProvider.overrideWithValue(services)],
      child: HikmahApp(services: services, routerConfig: router),
    ),
  );
}
