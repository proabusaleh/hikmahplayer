import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/di/app_scope.dart';
import 'core/di/app_services.dart';
import 'core/theme/app_theme.dart';

/// Root widget of Hikmah Player.
///
/// Wraps the shared [AppServices] in an [AppScope], exposes the Material 3
/// theme system (light / dark / system, dynamic color, seed override) and
/// boots the GoRouter navigation graph.
class HikmahApp extends StatelessWidget {
  const HikmahApp({
    super.key,
    required this.services,
    required this.routerConfig,
  });

  final AppServices services;
  final GoRouter routerConfig;

  @override
  Widget build(BuildContext context) {
    final controller = services.theme;
    return AppScope(
      services: services,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final seed = controller.effectiveSeed;
          return MaterialApp.router(
            title: 'Hikmah Player',
            debugShowCheckedModeBanner: false,
            themeMode: controller.themeMode,
            theme: AppTheme.light(seed: seed),
            darkTheme: AppTheme.dark(
              seed: seed,
              pureBlack: controller.usePureBlack,
            ),
            routerConfig: routerConfig,
          );
        },
      ),
    );
  }
}
