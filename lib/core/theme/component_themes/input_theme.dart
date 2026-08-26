import 'package:flutter/material.dart';

import '../app_dimensions.dart';

abstract final class AppInputTheme {
  static InputDecorationTheme light(ColorScheme scheme) =>
      _build(scheme, scheme.surfaceContainerHighest);

  static InputDecorationTheme dark(ColorScheme scheme) =>
      _build(scheme, scheme.surfaceContainerHigh);

  static InputDecorationTheme _build(ColorScheme scheme, Color fill) =>
      InputDecorationTheme(
        filled: true,
        fillColor: fill,
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
          borderSide: BorderSide(color: scheme.error),
        ),
      );
}
