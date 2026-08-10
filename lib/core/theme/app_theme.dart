import 'package:shadcn_flutter/shadcn_flutter.dart';

class AppTheme {
  static Typography get _customTypography {
    return const Typography.geist(
      h1: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        height: 1.25,
        letterSpacing: -0.5,
      ),
      h2: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.3,
      ),
      h3: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: -0.2,
      ),
      h4: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
      p: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        height: 1.4,
      ),
      textSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        height: 1.35,
      ),
      textMuted: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.normal,
        height: 1.35,
      ),
      textLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
      lead: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.normal,
        height: 1.4,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      colorScheme: ColorSchemes.darkZinc,
      typography: _customTypography,
      radius: 0.5,
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorSchemes.lightZinc,
      typography: _customTypography,
      radius: 0.5,
    );
  }
}
