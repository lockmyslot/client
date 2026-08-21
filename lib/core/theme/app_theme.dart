import 'package:flutter/material.dart';

class AppTheme {
  static const Color _seedColor = Color(0xFF3F51B5);
  static const String _fontFamily = 'GoogleSansFlex';

  static ThemeData darkTheme([ColorScheme? colorScheme]) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: _fontFamily,
      colorScheme:
          colorScheme ??
          ColorScheme.fromSeed(
            seedColor: _seedColor,
            brightness: Brightness.dark,
          ),
    );
  }

  static ThemeData lightTheme([ColorScheme? colorScheme]) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: _fontFamily,
      colorScheme:
          colorScheme ??
          ColorScheme.fromSeed(
            seedColor: _seedColor,
            brightness: Brightness.light,
          ),
    );
  }
}
