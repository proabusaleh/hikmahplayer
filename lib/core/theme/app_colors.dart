import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color primaryLight = Color(0xFF18C878);
  static const Color primaryDark = Color(0xFF18C878);
  static const Color primarySeed = Color(0xFF18C878);
  static const Color secondaryLight = Color(0xFF20B8A6);
  static const Color secondaryDark = Color(0xFF20B8A6);

  static const Color surfaceLight = Color(0xFFF5F5F5);
  static const Color surfaceContLight = Color(0xFFFAFAFA);
  static const Color onSurfaceLight = Color(0xFF1C1B1F);

  static const Color surfaceDark = Color(0xFF0B0B0B);
  static const Color surfaceContDark = Color(0xFF121212);
  static const Color elevatedDark = Color(0xFF181818);
  static const Color onSurfaceDark = Color(0xFFF5F5F5);
  static const Color onSurfaceVariantDark = Color(0xFFA7A7A7);
  static const Color dividerDark = Color(0xFF252525);

  static const Color playerBackground = Color(0xFF000000);
  static const Color playerControls = Color(0xFFF5F5F5);
  static const Color seekBarPlayed = Color(0xFF18C878);
  static const Color seekBarBuffered = Color(0x8018C878);
  static const Color seekBarRemaining = Color(0x33FFFFFF);

  // ─── Hikmah brand palette (Home Dashboard) ─────────────────────────
  static const Color deepNavy = Color(0xFF0A0E27);
  static const Color navySurface = Color(0xFF121736);
  static const Color navySurfaceVariant = Color(0xFF1A2045);
  static const Color primaryCyan = Color(0xFF3B9EFF);
  static const Color primaryPurple = Color(0xFF7B3FE4);
  static const Color primaryPink = Color(0xFFE535AB);

  static const List<SeedChoice> seedChoices = [
    SeedChoice('Emerald', 'Emerald', primarySeed),
    SeedChoice('Teal', 'Teal', Color(0xFF20B8A6)),
    SeedChoice('Blue', 'Blue', Color(0xFF1565C0)),
    SeedChoice('Purple', 'Purple', Color(0xFF5E35B1)),
    SeedChoice('Amber', 'Amber', Color(0xFFFFA000)),
    SeedChoice('Red', 'Red', Color(0xFFC62828)),
  ];

  static ColorScheme lightScheme({Color? seed}) => ColorScheme.fromSeed(
        seedColor: seed ?? primarySeed,
        brightness: Brightness.light,
        primary: primaryLight,
        secondary: secondaryLight,
        surface: surfaceLight,
        surfaceContainerHighest: surfaceContLight,
        onSurface: onSurfaceLight,
      );

  static ColorScheme darkScheme({Color? seed}) => ColorScheme.fromSeed(
        seedColor: seed ?? primarySeed,
        brightness: Brightness.dark,
        primary: primaryDark,
        secondary: secondaryDark,
        surface: surfaceDark,
        surfaceContainer: surfaceContDark,
        surfaceContainerHigh: elevatedDark,
        onSurface: onSurfaceDark,
        onSurfaceVariant: onSurfaceVariantDark,
        outlineVariant: dividerDark,
      );
}

class SeedChoice {
  const SeedChoice(this.id, this.label, this.color);

  final String id;
  final String label;
  final Color color;
}
