import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';

import 'app.dart';
import 'core/di/app_services.dart';
import 'core/router/app_router.dart';
import 'core/storage/storage_locations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await Hive.initFlutter();
  await StorageLocations.clearTemp();

  final services = await AppServices.create();
  unawaited(services.theme.refreshDynamicSeed());
  final router = createAppRouter(prefs: services.prefs);
  runApp(HikmahApp(services: services, routerConfig: router));
}
