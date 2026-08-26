import 'package:flutter/material.dart';

abstract final class AppBottomNavTheme {
  static NavigationBarThemeData light(ColorScheme scheme) =>
      _build(scheme, const Color(0xFF121212));

  static NavigationBarThemeData dark(ColorScheme scheme) =>
      _build(scheme, const Color(0xFF1E1E1E));

  static NavigationBarThemeData _build(ColorScheme scheme, Color surface) =>
      NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        height: 80,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w400,
            color: states.contains(WidgetState.selected)
                ? scheme.onSurface
                : scheme.onSurfaceVariant,
          ),
        ),
      );
}
