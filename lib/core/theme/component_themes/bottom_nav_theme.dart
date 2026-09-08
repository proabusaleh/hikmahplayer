import 'package:flutter/material.dart';

abstract final class AppBottomNavTheme {
  static NavigationBarThemeData light(ColorScheme scheme) =>
      _build(scheme, const Color(0xFF0B0B0B));

  static NavigationBarThemeData dark(ColorScheme scheme) =>
      _build(scheme, const Color(0xFF0B0B0B));

  static NavigationBarThemeData _build(ColorScheme scheme, Color surface) =>
      NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: scheme.primary.withValues(alpha: 0.18),
        height: 72,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
      );
}
