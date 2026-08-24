import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppSettings {
  const AppSettings({
    this.resumePlayback = true,
    this.backgroundAudio = true,
    this.autoScanOnStart = true,
    this.preferredSpeed = 1.0,
    this.themeMode = ThemeMode.system,
    this.dynamicColor = true,
    this.pureBlack = false,
  });

  final bool resumePlayback;
  final bool backgroundAudio;
  final bool autoScanOnStart;
  final double preferredSpeed;
  final ThemeMode themeMode;
  final bool dynamicColor;
  final bool pureBlack;

  AppSettings copyWith({
    bool? resumePlayback,
    bool? backgroundAudio,
    bool? autoScanOnStart,
    double? preferredSpeed,
    ThemeMode? themeMode,
    bool? dynamicColor,
    bool? pureBlack,
  }) {
    return AppSettings(
      resumePlayback: resumePlayback ?? this.resumePlayback,
      backgroundAudio: backgroundAudio ?? this.backgroundAudio,
      autoScanOnStart: autoScanOnStart ?? this.autoScanOnStart,
      preferredSpeed: preferredSpeed ?? this.preferredSpeed,
      themeMode: themeMode ?? this.themeMode,
      dynamicColor: dynamicColor ?? this.dynamicColor,
      pureBlack: pureBlack ?? this.pureBlack,
    );
  }
}

class Settings extends Notifier<AppSettings> {
  @override
  AppSettings build() => const AppSettings();

  Future<void> update(AppSettings settings) async {
    state = settings;
  }

  Future<void> reset() async {
    state = const AppSettings();
  }
}

final settingsProvider =
    NotifierProvider<Settings, AppSettings>(Settings.new);
