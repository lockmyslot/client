import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockmyslot_app/core/theme/item_color_utils.dart';

void main() {
  group('ItemColorUtils Unit Tests', () {
    test('parseHexColor parses valid 6-char hex strings with or without hash', () {
      expect(parseHexColor('#3B82F6'), equals(const Color(0xFF3B82F6)));
      expect(parseHexColor('3B82F6'), equals(const Color(0xFF3B82F6)));
      expect(parseHexColor('#ef4444'), equals(const Color(0xFFEF4444)));
      expect(parseHexColor('#10b981'), equals(const Color(0xFF10B981)));
    });

    test('parseHexColor parses valid 8-char hex strings', () {
      expect(parseHexColor('#803B82F6'), equals(const Color(0x803B82F6)));
      expect(parseHexColor('FF3B82F6'), equals(const Color(0xFF3B82F6)));
    });

    test('parseHexColor returns null for invalid formats', () {
      expect(parseHexColor(null), isNull);
      expect(parseHexColor(''), isNull);
      expect(parseHexColor('xyz'), isNull);
      expect(parseHexColor('#12'), isNull);
      expect(parseHexColor('#123456789'), isNull);
    });

    test('toHexColor formats Color to uppercase 7-character hex', () {
      expect(toHexColor(const Color(0xFF3B82F6)), equals('#3B82F6'));
      expect(toHexColor(const Color(0xFF10B981)), equals('#10B981'));
      expect(toHexColor(const Color(0xFFEF4444)), equals('#EF4444'));
    });

    test('getItemColorStyle uses itemColor when useItemColors is true', () {
      final colorScheme = ColorScheme.fromSeed(seedColor: Colors.blue);
      final itemColor = const Color(0xFF10B981);

      // Light mode
      final lightStyle = getItemColorStyle(
        itemColor: itemColor,
        useItemColors: true,
        colorScheme: colorScheme,
        isDark: false,
      );
      expect(lightStyle.foreground, equals(itemColor));
      expect(lightStyle.background, equals(itemColor.withValues(alpha: 0.16)));
      expect(lightStyle.border, equals(itemColor.withValues(alpha: 0.35)));

      // Dark mode
      final darkStyle = getItemColorStyle(
        itemColor: itemColor,
        useItemColors: true,
        colorScheme: colorScheme,
        isDark: true,
      );
      expect(darkStyle.foreground, equals(itemColor));
      expect(darkStyle.background, equals(itemColor.withValues(alpha: 0.22)));
      expect(darkStyle.border, equals(itemColor.withValues(alpha: 0.45)));
    });

    test('getItemColorStyle falls back to theme colors when useItemColors is false', () {
      final colorScheme = ColorScheme.fromSeed(seedColor: Colors.indigo);
      final itemColor = const Color(0xFFEF4444);

      final style = getItemColorStyle(
        itemColor: itemColor,
        useItemColors: false,
        colorScheme: colorScheme,
        isDark: false,
      );
      expect(style.background, equals(colorScheme.primaryContainer));
      expect(style.foreground, equals(colorScheme.onPrimaryContainer));
      expect(
        style.border,
        equals(colorScheme.outlineVariant.withValues(alpha: 0.35)),
      );
    });

    test('getItemColorStyle falls back to theme colors when itemColor is null', () {
      final colorScheme = ColorScheme.fromSeed(seedColor: Colors.purple);

      final style = getItemColorStyle(
        itemColor: null,
        useItemColors: true,
        colorScheme: colorScheme,
        isDark: true,
      );
      expect(style.background, equals(colorScheme.primaryContainer));
      expect(style.foreground, equals(colorScheme.onPrimaryContainer));
    });

    test('kItemColorPalette contains at least 12 distinct colors', () {
      expect(kItemColorPalette.length, greaterThanOrEqualTo(12));
      final hexSet = kItemColorPalette.map((o) => o.hex).toSet();
      expect(hexSet.length, equals(kItemColorPalette.length));
    });
  });
}
