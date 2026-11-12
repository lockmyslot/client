import 'package:flutter/material.dart';

/// Unified shape scale across the app adhering strictly to Material 3 specifications.
class AppShapes {
  /// Tier 1: Cards & Large Surface Containers (16dp)
  static const double cardRadius = 16.0;
  static final BorderRadius card = BorderRadius.circular(cardRadius);
  static const Radius cardRadiusValue = Radius.circular(cardRadius);

  /// Tier 2: Controls, Inputs & Buttons (12dp)
  static const double controlRadius = 12.0;
  static final BorderRadius control = BorderRadius.circular(controlRadius);
  static const Radius controlRadiusValue = Radius.circular(controlRadius);

  /// Tier 3: Compact Tags, Badges & Indicators (8dp)
  static const double tagRadius = 8.0;
  static final BorderRadius tag = BorderRadius.circular(tagRadius);
  static const Radius tagRadiusValue = Radius.circular(tagRadius);

  /// Tier 4: Bottom Sheets & Dialogs (28dp)
  static const double sheetRadius = 28.0;
  static const BorderRadius sheetTop =
      BorderRadius.vertical(top: Radius.circular(sheetRadius));
  static final BorderRadius dialog = BorderRadius.circular(sheetRadius);
}

class AppTheme {
  static const Color _seedColor = Color(0xFF18181B);
  static const String _fontFamily = 'GoogleSansFlexRounded';

  /// Builds the fallback palette used when the platform does not provide
  /// dynamic colors.
  ///
  /// The default tonal-spot variant amplifies the seed's blue hue, which turns
  /// the container roles into lavender/periwinkle pills that clash with the
  /// neutral slate surfaces. The neutral variant keeps the same tonal
  /// structure while staying in the slate family.
  static ColorScheme _fallbackScheme(Brightness brightness) {
    return ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.neutral,
    );
  }

  /// Pulls a wallpaper-derived scheme back into the low-chroma slate family.
  ///
  /// Android's dynamic colors can make container roles (pills, badges, cards)
  /// much more saturated than the rest of the UI. Re-seeding the dynamic
  /// primary with the neutral variant keeps the wallpaper's hue while toning
  /// the containers down so they stay visually consistent.
  static ColorScheme harmonizeDynamic(
    ColorScheme dynamicScheme,
    Brightness brightness,
  ) {
    return ColorScheme.fromSeed(
      seedColor: dynamicScheme.primary,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.neutral,
    );
  }

  /// Builds a scheme from a user's preferred seed color.
  static ColorScheme schemeFromSeed(
    Color seedColor,
    Brightness brightness,
  ) {
    return ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
      dynamicSchemeVariant: seedColor == _seedColor
          ? DynamicSchemeVariant.neutral
          : DynamicSchemeVariant.tonalSpot,
    );
  }

  static InputDecorationTheme _inputDecorationTheme(ColorScheme cs) {
    final borderRadius = AppShapes.control;
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
    final cs = colorScheme ?? _fallbackScheme(Brightness.dark);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: _fontFamily,
      colorScheme: cs,
      inputDecorationTheme: _inputDecorationTheme(cs),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: cs.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: AppShapes.card,
          side: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cs.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppShapes.sheetTop),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppShapes.dialog),
        backgroundColor: cs.surfaceContainerHigh,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppShapes.control),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: AppShapes.control),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: AppShapes.control),
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: cs.onSurface,
        ),
        headlineMedium: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 32,
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
    final cs = colorScheme ?? _fallbackScheme(Brightness.light);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: _fontFamily,
      colorScheme: cs,
      inputDecorationTheme: _inputDecorationTheme(cs),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: cs.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: AppShapes.card,
          side: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cs.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppShapes.sheetTop),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppShapes.dialog),
        backgroundColor: cs.surfaceContainerHigh,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppShapes.control),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: AppShapes.control),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: AppShapes.control),
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: cs.onSurface,
        ),
        headlineMedium: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 32,
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
