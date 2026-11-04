import 'package:flutter/material.dart';

/// Representation of a color choice in the curated item palette.
class ItemColorOption {
  final String key;
  final String label;
  final String hex;
  final Color color;

  const ItemColorOption({
    required this.key,
    required this.label,
    required this.hex,
    required this.color,
  });
}

/// 12 curated vibrant and accessible colors suited for light and dark themes.
const List<ItemColorOption> kItemColorPalette = [
  ItemColorOption(
    key: 'slate',
    label: 'Slate',
    hex: '#64748B',
    color: Color(0xFF64748B),
  ),
  ItemColorOption(
    key: 'red',
    label: 'Red',
    hex: '#EF4444',
    color: Color(0xFFEF4444),
  ),
  ItemColorOption(
    key: 'orange',
    label: 'Orange',
    hex: '#F97316',
    color: Color(0xFFF97316),
  ),
  ItemColorOption(
    key: 'amber',
    label: 'Amber',
    hex: '#F59E0B',
    color: Color(0xFFF59E0B),
  ),
  ItemColorOption(
    key: 'emerald',
    label: 'Emerald',
    hex: '#10B981',
    color: Color(0xFF10B981),
  ),
  ItemColorOption(
    key: 'teal',
    label: 'Teal',
    hex: '#14B8A6',
    color: Color(0xFF14B8A6),
  ),
  ItemColorOption(
    key: 'cyan',
    label: 'Cyan',
    hex: '#06B6D4',
    color: Color(0xFF06B6D4),
  ),
  ItemColorOption(
    key: 'blue',
    label: 'Blue',
    hex: '#3B82F6',
    color: Color(0xFF3B82F6),
  ),
  ItemColorOption(
    key: 'indigo',
    label: 'Indigo',
    hex: '#6366F1',
    color: Color(0xFF6366F1),
  ),
  ItemColorOption(
    key: 'violet',
    label: 'Violet',
    hex: '#8B5CF6',
    color: Color(0xFF8B5CF6),
  ),
  ItemColorOption(
    key: 'pink',
    label: 'Pink',
    hex: '#EC4899',
    color: Color(0xFFEC4899),
  ),
  ItemColorOption(
    key: 'rose',
    label: 'Rose',
    hex: '#F43F5E',
    color: Color(0xFFF43F5E),
  ),
];

/// Safely parses a hex color string like "#3B82F6" or "3B82F6" or "#FF3B82F6".
Color? parseHexColor(String? hex) {
  if (hex == null) return null;
  var clean = hex.trim().replaceAll('#', '');
  if (clean.length == 6) {
    clean = 'FF$clean';
  }
  if (clean.length != 8) return null;
  final val = int.tryParse(clean, radix: 16);
  if (val == null) return null;
  return Color(val);
}

/// Formats a Flutter Color to a 7-character hex string ("#RRGGBB").
String toHexColor(Color color) {
  final r = (color.r * 255).round().toRadixString(16).padLeft(2, '0');
  final g = (color.g * 255).round().toRadixString(16).padLeft(2, '0');
  final b = (color.b * 255).round().toRadixString(16).padLeft(2, '0');
  return '#$r$g$b'.toUpperCase();
}

/// Container styling computed from an item color and theme mode.
class ItemColorStyle {
  final Color background;
  final Color foreground;
  final Color border;

  const ItemColorStyle({
    required this.background,
    required this.foreground,
    required this.border,
  });
}

/// Resolves the avatar container background, foreground icon/text, and border
/// based on item color, whether item colors are enabled, and brightness.
ItemColorStyle getItemColorStyle({
  Color? itemColor,
  required bool useItemColors,
  required ColorScheme colorScheme,
  required bool isDark,
}) {
  if (useItemColors && itemColor != null) {
    if (isDark) {
      return ItemColorStyle(
        background: itemColor.withValues(alpha: 0.22),
        foreground: itemColor,
        border: itemColor.withValues(alpha: 0.45),
      );
    } else {
      return ItemColorStyle(
        background: itemColor.withValues(alpha: 0.16),
        foreground: itemColor,
        border: itemColor.withValues(alpha: 0.35),
      );
    }
  }

  return ItemColorStyle(
    background: colorScheme.primaryContainer,
    foreground: colorScheme.onPrimaryContainer,
    border: colorScheme.outlineVariant.withValues(alpha: 0.35),
  );
}
