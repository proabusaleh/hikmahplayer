import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color primaryLight = Color(0xFF00796B);
  static const Color primaryDark = Color(0xFF4DB6AC);
  static const Color primarySeed = Color(0xFF009688);

  static const Color secondaryLight = Color(0xFFFFA000);
  static const Color secondaryDark = Color(0xFFFFD54F);

  static const Color tertiaryLight = Color(0xFF5E35B1);
  static const Color tertiaryDark = Color(0xFFB39DDB);

  static const Color surfaceLight = Color(0xFFFAFAFA);
  static const Color surfaceContLight = Color(0xFFFFFFFF);
  static const Color onSurfaceLight = Color(0xFF1C1B1F);

  static const Color surfaceDark = Color(0xFF121212);
  static const Color surfaceContDark = Color(0xFF1E1E1E);
  static const Color onSurfaceDark = Color(0xFFE6E1E5);

  static const Color playerBackground = Color(0xFF000000);
  static const Color playerControls = Color(0xFFFFFFFF);
  static const Color seekBarPlayed = Color(0xFF4DB6AC);
  static const Color seekBarBuffered = Color(0x804DB6AC);
  static const Color seekBarRemaining = Color(0x33FFFFFF);

  static const List<SeedChoice> seedChoices = [
    SeedChoice('Teal', 'Teal', primarySeed),
    SeedChoice('Blue', 'Blue', Color(0xFF1565C0)),
    SeedChoice('Purple', 'Purple', tertiaryLight),
    SeedChoice('Green', 'Green', Color(0xFF2E7D32)),
    SeedChoice('Amber', 'Amber', secondaryLight),
    SeedChoice('Red', 'Red', Color(0xFFC62828)),
  ];

  static ColorScheme lightScheme({Color? seed}) => ColorScheme.fromSeed(
        seedColor: seed ?? primarySeed,
        brightness: Brightness.light,
        primary: primaryLight,
        secondary: secondaryLight,
        tertiary: tertiaryLight,
        surface: surfaceLight,
        surfaceContainerHighest: surfaceContLight,
        onSurface: onSurfaceLight,
      );

  static ColorScheme darkScheme({Color? seed}) => ColorScheme.fromSeed(
        seedColor: seed ?? primarySeed,
        brightness: Brightness.dark,
        primary: primaryDark,
        secondary: secondaryDark,
        tertiary: tertiaryDark,
        surface: surfaceDark,
        surfaceContainerHighest: surfaceContDark,
        onSurface: onSurfaceDark,
      );
}

class SeedChoice {
  const SeedChoice(this.id, this.label, this.color);

  final String id;
  final String label;
  final Color color;
}
