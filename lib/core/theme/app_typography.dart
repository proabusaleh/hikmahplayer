import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTypography {
  static const String uiFamily = 'Inter';
  static const String headingFamily = 'Poppins';
  static const List<String> arabicFallback = ['Noto Sans Arabic'];

  static TextTheme textTheme(Brightness brightness) {
    final base =
        brightness == Brightness.light ? ThemeData.light() : ThemeData.dark();
    final t = base.textTheme;
    TextStyle heading(TextStyle? style) => GoogleFonts.poppins(
          textStyle: style,
        ).copyWith(fontFamilyFallback: arabicFallback);
    TextStyle body(TextStyle? style) => GoogleFonts.inter(
          textStyle: style,
        ).copyWith(fontFamilyFallback: arabicFallback);

    return TextTheme(
      displayLarge: heading(t.displayLarge),
      displayMedium: heading(t.displayMedium),
      displaySmall: heading(t.displaySmall),
      headlineLarge: heading(t.headlineLarge),
      headlineMedium: heading(t.headlineMedium),
      headlineSmall: heading(t.headlineSmall),
      titleLarge: heading(t.titleLarge),
      titleMedium: body(t.titleMedium),
      titleSmall: body(t.titleSmall),
      bodyLarge: body(t.bodyLarge),
      bodyMedium: body(t.bodyMedium),
      bodySmall: body(t.bodySmall),
      labelLarge: body(t.labelLarge),
      labelMedium: body(t.labelMedium),
      labelSmall: body(t.labelSmall),
    );
  }
}
