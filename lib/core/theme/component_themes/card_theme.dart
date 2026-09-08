import 'package:flutter/material.dart';

import '../app_dimensions.dart';

abstract final class AppCardTheme {
  static CardThemeData light(ColorScheme scheme) => _build(scheme);

  static CardThemeData dark(ColorScheme scheme) => _build(scheme);

  static CardThemeData _build(ColorScheme scheme) => CardThemeData(
        color: scheme.surfaceContainerHigh,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.25)),
        ),
      );
}
