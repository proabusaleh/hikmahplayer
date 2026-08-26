import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/prefs_service.dart';
import 'services_provider.dart';

ThemeMode _themeModeFromName(String name) {
  switch (name) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
}

/// Snapshot of user preferences, mirroring [PrefsService] defaults.
class AppSettings {
  const AppSettings({
    this.resumePlayback = true,
    this.autoPlay = false,
    this.showLyrics = true,
    this.incognitoMode = false,
    this.defaultPlaybackSpeed = 1.0,
    this.defaultVideoFit = PrefsService.kDefaultVideoFit,
    this.audioEqualizerPreset = 'flat',
    this.themeMode = ThemeMode.system,
    this.seedColorIndex = 0,
    this.dynamicColor = false,
    this.pureBlack = false,
  });

  final bool resumePlayback;
  final bool autoPlay;
  final bool showLyrics;
  final bool incognitoMode;
  final double defaultPlaybackSpeed;
  final String defaultVideoFit;
  final String audioEqualizerPreset;

  // Theme fields route through ThemeController so the UI rebuilds.
  final ThemeMode themeMode;
  final int seedColorIndex;
  final bool dynamicColor;
  final bool pureBlack;

  AppSettings copyWith({
    bool? resumePlayback,
    bool? autoPlay,
    bool? showLyrics,
    bool? incognitoMode,
    double? defaultPlaybackSpeed,
    String? defaultVideoFit,
    String? audioEqualizerPreset,
    ThemeMode? themeMode,
    int? seedColorIndex,
    bool? dynamicColor,
    bool? pureBlack,
  }) {
    return AppSettings(
      resumePlayback: resumePlayback ?? this.resumePlayback,
      autoPlay: autoPlay ?? this.autoPlay,
      showLyrics: showLyrics ?? this.showLyrics,
      incognitoMode: incognitoMode ?? this.incognitoMode,
      defaultPlaybackSpeed: defaultPlaybackSpeed ?? this.defaultPlaybackSpeed,
      defaultVideoFit: defaultVideoFit ?? this.defaultVideoFit,
      audioEqualizerPreset: audioEqualizerPreset ?? this.audioEqualizerPreset,
      themeMode: themeMode ?? this.themeMode,
      seedColorIndex: seedColorIndex ?? this.seedColorIndex,
      dynamicColor: dynamicColor ?? this.dynamicColor,
      pureBlack: pureBlack ?? this.pureBlack,
    );
  }
}

class Settings extends Notifier<AppSettings> {
  @override
  AppSettings build() => _snapshot();

  PrefsService get _prefs => ref.read(appServicesProvider).prefs;

  AppSettings _snapshot() {
    return AppSettings(
      resumePlayback: _prefs.resumePlayback,
      autoPlay: _prefs.autoPlay,
      showLyrics: _prefs.showLyrics,
      incognitoMode: _prefs.incognitoMode,
      defaultPlaybackSpeed: _prefs.defaultPlaybackSpeed,
      defaultVideoFit: _prefs.defaultVideoFit,
      audioEqualizerPreset: _prefs.audioEqualizerPreset,
      themeMode: _themeModeFromName(_prefs.themeModeName),
      seedColorIndex: _prefs.seedColorIndex,
      dynamicColor: _prefs.useDynamicColor,
      pureBlack: _prefs.usePureBlack,
    );
  }

  /// Persists every field of [settings]; theme fields go through the shared
  /// [ThemeController] so the material app rebuilds immediately.
  Future<void> update(AppSettings settings) async {
    _prefs
      ..resumePlayback = settings.resumePlayback
      ..autoPlay = settings.autoPlay
      ..showLyrics = settings.showLyrics
      ..incognitoMode = settings.incognitoMode
      ..defaultPlaybackSpeed = settings.defaultPlaybackSpeed
      ..defaultVideoFit = settings.defaultVideoFit
      ..audioEqualizerPreset = settings.audioEqualizerPreset;

    final theme = ref.read(appServicesProvider).theme;
    await theme.setThemeMode(settings.themeMode);
    if (_prefs.seedColorIndex != settings.seedColorIndex) {
      await theme.setSeedColorIndex(settings.seedColorIndex);
    }
    if (_prefs.useDynamicColor != settings.dynamicColor) {
      await theme.setUseDynamicColor(settings.dynamicColor);
    }

    state = _snapshot();
  }

  Future<void> reset() => update(const AppSettings());
}

final settingsProvider =
    NotifierProvider<Settings, AppSettings>(Settings.new);
