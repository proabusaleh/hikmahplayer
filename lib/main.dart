import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';

import 'app.dart';
import 'core/di/app_services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await Hive.initFlutter();

  final box = await Hive.openBox('hikmah_prefs');
  final isFirstRun = !(box.get('has_launched', defaultValue: false) as bool);

  final services = AppServices();
  runApp(HikmahApp(services: services, isFirstRun: isFirstRun));
}
