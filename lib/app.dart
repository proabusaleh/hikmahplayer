import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/di/app_scope.dart';
import 'core/di/app_services.dart';
import 'core/themes/app_theme.dart';
import 'features/splash/presentation/screens/permission_screen.dart';
import 'features/splash/presentation/screens/scanning_screen.dart';
import 'features/splash/presentation/screens/splash_screen.dart';
import 'presentation/screens/home/home_shell.dart';

/// Onboarding phases.
enum _Phase { splash, permission, scan, ready }

/// Root widget of Hikmah Player.
///
/// Wraps the shared [AppServices] in an [AppScope] and boots the
/// splash → permission → scan → [HomeShell] flow.
class HikmahApp extends StatefulWidget {
  const HikmahApp({
    super.key,
    required this.services,
    required this.isFirstRun,
  });

  final AppServices services;
  final bool isFirstRun;

  @override
  State<HikmahApp> createState() => _HikmahAppState();
}

class _HikmahAppState extends State<HikmahApp> {
  _Phase _phase = _Phase.splash;

  @override
  void initState() {
    super.initState();
    // If not first run, skip permission/scan and go straight to home
    // after splash.
    if (!widget.isFirstRun) {
      _phase = _Phase.splash;
    }
  }

  void _onSplashReady() {
    if (!widget.isFirstRun) {
      // Returning user — skip onboarding, go straight to app.
      setState(() => _phase = _Phase.ready);
    } else {
      // First time — show permissions.
      setState(() => _phase = _Phase.permission);
    }
  }

  void _onPermissionsGranted() {
    setState(() => _phase = _Phase.scan);
  }

  void _onScanComplete() async {
    // Persist that we've completed onboarding.
    final box = Hive.box('hikmah_prefs');
    await box.put('has_launched', true);
    setState(() => _phase = _Phase.ready);
  }

  Widget _buildCurrentScreen() {
    switch (_phase) {
      case _Phase.splash:
        return SplashScreen(onReady: _onSplashReady);
      case _Phase.permission:
        return PermissionScreen(onPermissionsGranted: _onPermissionsGranted);
      case _Phase.scan:
        return ScanningScreen(onScanComplete: _onScanComplete);
      case _Phase.ready:
        return const HomeShell();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      services: widget.services,
      child: MaterialApp(
        title: 'Hikmah Player',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        home: _buildCurrentScreen(),
      ),
    );
  }
}
