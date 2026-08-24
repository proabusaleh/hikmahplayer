import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeState {
  const ThemeState({
    this.mode = ThemeMode.system,
    this.seedColor = const Color(0xFF1B5E20),
    this.dynamicColor = true,
    this.pureBlack = false,
  });

  final ThemeMode mode;
  final Color seedColor;
  final bool dynamicColor;
  final bool pureBlack;

  ThemeState copyWith({
    ThemeMode? mode,
    Color? seedColor,
    bool? dynamicColor,
    bool? pureBlack,
  }) {
    return ThemeState(
      mode: mode ?? this.mode,
      seedColor: seedColor ?? this.seedColor,
      dynamicColor: dynamicColor ?? this.dynamicColor,
      pureBlack: pureBlack ?? this.pureBlack,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemeState &&
          other.mode == mode &&
          other.seedColor == seedColor &&
          other.dynamicColor == dynamicColor &&
          other.pureBlack == pureBlack;

  @override
  int get hashCode => Object.hash(mode, seedColor, dynamicColor, pureBlack);
}

class ThemeController extends Notifier<ThemeState> {
  @override
  ThemeState build() => const ThemeState();

  void setMode(ThemeMode mode) {
    state = state.copyWith(mode: mode);
  }

  void setSeedColor(Color color) {
    state = state.copyWith(seedColor: color);
  }

  void toggleDynamic() {
    state = state.copyWith(dynamicColor: !state.dynamicColor);
  }

  void togglePureBlack() {
    state = state.copyWith(pureBlack: !state.pureBlack);
  }
}

final themeProvider =
    NotifierProvider<ThemeController, ThemeState>(ThemeController.new);
