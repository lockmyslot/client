import 'package:flutter/material.dart';

class AppTheme {
  static const Color _seedColor = Color(0xFF3F51B5);
  static const String _fontFamily = 'GoogleSansFlexRounded';

  static InputDecorationTheme _inputDecorationTheme(ColorScheme cs) {
    final borderRadius = BorderRadius.circular(12);
    return InputDecorationTheme(
      filled: false,
      border: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: cs.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: cs.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: cs.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: cs.error, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  static ThemeData darkTheme([ColorScheme? colorScheme]) {
    final cs =
        colorScheme ??
        ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.dark,
        );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: _fontFamily,
      colorScheme: cs,
      inputDecorationTheme: _inputDecorationTheme(cs),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: cs.onSurface,
        ),
      ),
      textTheme: TextTheme(
        headlineMedium: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: cs.onSurface,
        ),
        headlineLarge: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: cs.onSurface,
        ),
      ),
    );
  }

  static ThemeData lightTheme([ColorScheme? colorScheme]) {
    final cs =
        colorScheme ??
        ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.light,
        );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: _fontFamily,
      colorScheme: cs,
      inputDecorationTheme: _inputDecorationTheme(cs),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: cs.onSurface,
        ),
      ),
      textTheme: TextTheme(
        headlineMedium: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: cs.onSurface,
        ),
        headlineLarge: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: cs.onSurface,
        ),
      ),
    );
  }
}
