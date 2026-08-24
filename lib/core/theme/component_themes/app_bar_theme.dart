import 'package:flutter/material.dart';


abstract final class AppAppBarTheme {
  static AppBarTheme light(ColorScheme scheme) => AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: scheme.surfaceTint,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      );

  static AppBarTheme dark(ColorScheme scheme) => light(scheme);
}
