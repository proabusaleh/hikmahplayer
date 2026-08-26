import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme_controller.dart';
import 'services_provider.dart';

/// Immutable snapshot of the theme configuration.
class ThemeState {
  const ThemeState({
    this.mode = ThemeMode.system,
    this.seedColor = const Color(0xFF009688),
    this.dynamicColor = false,
    this.pureBlack = false,
  });

  final ThemeMode mode;

  /// The seed currently in effect: OS accent when dynamic color is enabled
  /// and available, otherwise the user's chosen palette color.
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

/// Riverpod facade over the shared [ThemeController].
///
/// All mutations go through the underlying controller (single source of
/// truth, persisted via [PrefsService]); state mirrors its notifications so
/// external changes (e.g. dynamic accent refresh at startup) propagate.
class ThemeNotifier extends Notifier<ThemeState> {
  ThemeController get _controller => ref.read(appServicesProvider).theme;

  @override
  ThemeState build() {
    final controller = ref.watch(appServicesProvider).theme;
    var active = true;
    void onUpdate() {
      if (!active) return;
      state = _snapshot(controller);
    }

    ref.onDispose(() {
      active = false;
      controller.removeListener(onUpdate);
    });
    controller.addListener(onUpdate);
    return _snapshot(controller);
  }

  static ThemeState _snapshot(ThemeController controller) {
    return ThemeState(
      mode: controller.themeMode,
      seedColor: controller.effectiveSeed,
      dynamicColor: controller.useDynamicColor,
      pureBlack: controller.usePureBlack,
    );
  }

  Future<void> setMode(ThemeMode mode) => _controller.setThemeMode(mode);

  /// Selects a palette entry by index (see `AppColors.seedChoices`).
  Future<void> setSeedColorIndex(int index) =>
      _controller.setSeedColorIndex(index);

  Future<void> toggleDynamic() =>
      _controller.setUseDynamicColor(!_controller.useDynamicColor);

  Future<void> togglePureBlack() =>
      _controller.setUsePureBlack(!_controller.usePureBlack);
}

final themeProvider =
    NotifierProvider<ThemeNotifier, ThemeState>(ThemeNotifier.new);
