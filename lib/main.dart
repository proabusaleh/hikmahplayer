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

void main() {
  // Any uncaught error is printed loudly (it is the source of "blank screen"
  // reports on release builds) instead of silently stopping the frame loop.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('Hikmah fatal error: ${details.exceptionAsString()}');
  };
  runZonedGuarded(() => _boot(), (error, stack) {
    debugPrint('Hikmah uncaught error: $error\n$stack');
    _runFallback(error);
  });
}

Future<void> _boot() async {
  try {
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
    // Keep the library fresh on later launches: re-discover device media
    // in the background once the user has granted access during onboarding.
    unawaited(_refreshMediaLibrary(services));
  } catch (error, stack) {
    // Never leave the user staring at a blank screen: surface the failure so
    // the underlying cause is visible and can be fixed.
    debugPrint('Hikmah startup failure: $error\n$stack');
    _runFallback(error);
  }
}

/// Re-imports the on-device media library after onboarding is complete.
///
/// Runs off the critical path and swallows errors: a failed or in-flight
/// scan must never block the UI (and the user can trigger a rescan from the
/// library screens).
Future<void> _refreshMediaLibrary(AppServices services) async {
  if (!services.prefs.onboardingCompleted) return;
  try {
    final result = await services.mediaScan.scanAll();
    debugPrint('Hikmah media scan: ${result.toString()}');
  } catch (error, stack) {
    debugPrint('Hikmah media scan failed: $error\n$stack');
  }
}

void _runFallback(Object error) {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Hikmah Player failed to start',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                SelectableText(
                  '$error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
