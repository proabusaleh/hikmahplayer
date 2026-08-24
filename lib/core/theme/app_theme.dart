import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_dimensions.dart';
import 'app_typography.dart';
import 'component_themes/app_bar_theme.dart';
import 'component_themes/bottom_nav_theme.dart';
import 'component_themes/button_theme.dart';
import 'component_themes/card_theme.dart';
import 'component_themes/dialog_theme.dart';
import 'component_themes/input_theme.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light({ColorScheme? dynamicScheme, Color? seed}) =>
      _build(
        brightness: Brightness.light,
        scheme: dynamicScheme?.copyWith(brightness: Brightness.light) ??
            AppColors.lightScheme(seed: seed),
      );

  static ThemeData dark({
    ColorScheme? dynamicScheme,
    Color? seed,
    bool pureBlack = false,
  }) =>
      _build(
        brightness: Brightness.dark,
        scheme: dynamicScheme?.copyWith(brightness: Brightness.dark) ??
            AppColors.darkScheme(seed: seed),
        pureBlack: pureBlack,
      );

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme scheme,
    bool pureBlack = false,
  }) {
    var effectiveScheme = scheme;
    if (pureBlack && brightness == Brightness.dark) {
      effectiveScheme = scheme.copyWith(
        surface: const Color(0xFF000000),
        surfaceContainerLowest: const Color(0xFF000000),
        surfaceContainerLow: const Color(0xFF0A0A0A),
        surfaceContainer: const Color(0xFF121212),
        surfaceContainerHigh: const Color(0xFF1A1A1A),
        surfaceContainerHighest: const Color(0xFF222222),
      );
    }

    final isLight = brightness == Brightness.light;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: effectiveScheme,
      scaffoldBackgroundColor:
          isLight ? AppColors.surfaceLight : AppColors.surfaceDark,
      textTheme: AppTypography.textTheme(brightness),
      appBarTheme: AppAppBarTheme.light(effectiveScheme),
      navigationBarTheme: AppBottomNavTheme.light(effectiveScheme),
      cardTheme: AppCardTheme.light(effectiveScheme),
      filledButtonTheme: AppButtonTheme.filled(effectiveScheme),
      elevatedButtonTheme: AppButtonTheme.elevated(effectiveScheme),
      outlinedButtonTheme: AppButtonTheme.outlined(effectiveScheme),
      textButtonTheme: AppButtonTheme.text(effectiveScheme),
      floatingActionButtonTheme: AppButtonTheme.fab(effectiveScheme),
      inputDecorationTheme: AppInputTheme.light(effectiveScheme),
      dialogTheme: AppDialogTheme.light(effectiveScheme),
      chipTheme: ChipThemeData(
        backgroundColor: effectiveScheme.surfaceContainerHigh,
        selectedColor: effectiveScheme.primaryContainer,
        labelStyle: TextStyle(color: effectiveScheme.onSurface),
        side: BorderSide(
          color: effectiveScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.seekBarPlayed,
        inactiveTrackColor: AppColors.seekBarRemaining,
        valueIndicatorColor: effectiveScheme.primary,
        thumbColor: effectiveScheme.primary,
        overlayColor: effectiveScheme.primary.withValues(alpha: 0.12),
      ),
      dividerTheme: DividerThemeData(
        color: effectiveScheme.outlineVariant.withValues(alpha: 0.5),
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: effectiveScheme.inverseSurface,
        contentTextStyle: TextStyle(color: effectiveScheme.onInverseSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: effectiveScheme.surfaceContainerLow,
        modalBackgroundColor: effectiveScheme.surfaceContainerLow,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusCard + 12),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: effectiveScheme.onSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: effectiveScheme.primary,
        unselectedLabelColor: effectiveScheme.onSurfaceVariant,
        indicatorColor: effectiveScheme.primary,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: effectiveScheme.primary,
        linearTrackColor: AppColors.seekBarRemaining,
      ),
      visualDensity: VisualDensity.standard,
    );
  }
}
