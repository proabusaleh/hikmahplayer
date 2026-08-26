import 'package:flutter/material.dart';

import '../app_dimensions.dart';

abstract final class AppDialogTheme {
  static DialogThemeData light(ColorScheme scheme) => _build(scheme);

  static DialogThemeData dark(ColorScheme scheme) => _build(scheme);

  static DialogThemeData _build(ColorScheme scheme) => DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: scheme.surfaceTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusCard + 4),
        ),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      );
}
