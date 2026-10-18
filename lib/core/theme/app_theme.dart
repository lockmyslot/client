import 'package:flutter/material.dart';

class AppTheme {
  static const Color _seedColor = Color(0xFF3F51B5);
  static const String _fontFamily = 'GoogleSansFlexRounded';

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
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
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
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }
}
