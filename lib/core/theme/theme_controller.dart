import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

import '../storage/prefs_service.dart';
import 'app_colors.dart';

class ThemeController extends ChangeNotifier {
  ThemeController(this._prefs);

  final PrefsService _prefs;

  Color? _dynamicSeed;

  /// Accent color provided by the OS, if any.
  ///
  /// Resolved once at startup through a platform channel instead of
  /// [DynamicColorBuilder], whose callback types come from a third-party
  /// package and are not assignable to Flutter's own [ColorScheme].
  Color? get dynamicSeed => _dynamicSeed;

  /// The seed used for building color schemes.
  Color get effectiveSeed =>
      useDynamicColor ? (_dynamicSeed ?? seedChoice.color) : seedChoice.color;

  Future<void> refreshDynamicSeed() async {
    try {
      _dynamicSeed = await DynamicColorPlugin.getAccentColor();
    } catch (_) {
      _dynamicSeed = null;
    }
    notifyListeners();
  }

  ThemeMode get themeMode {
    switch (_prefs.themeModeName) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  bool get useDynamicColor => _prefs.useDynamicColor;
  bool get usePureBlack => _prefs.usePureBlack;

  SeedChoice get seedChoice {
    final index = _prefs.seedColorIndex;
    if (index < 0 || index >= AppColors.seedChoices.length) {
      return AppColors.seedChoices.first;
    }
    return AppColors.seedChoices[index];
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _prefs.themeModeName = mode.name;
    notifyListeners();
  }

  Future<void> setUseDynamicColor(bool value) async {
    _prefs.useDynamicColor = value;
    notifyListeners();
  }

  Future<void> setSeedColorIndex(int index) async {
    _prefs.seedColorIndex = index;
    notifyListeners();
  }

  Future<void> setUsePureBlack(bool value) async {
    _prefs.usePureBlack = value;
    notifyListeners();
  }
}
