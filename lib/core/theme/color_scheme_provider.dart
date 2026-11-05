import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'item_color_utils.dart';
import 'theme_provider.dart';

enum ColorSchemeSource {
  materialYou,
  preferred,
}

class PreferredColorOption {
  final String key;
  final String label;
  final Color color;

  const PreferredColorOption({
    required this.key,
    required this.label,
    required this.color,
  });
}

const List<PreferredColorOption> kPreferredColorOptions = [
  PreferredColorOption(
    key: 'slate',
    label: 'Slate',
    color: Color(0xFF18181B),
  ),
  PreferredColorOption(
    key: 'blue',
    label: 'Blue',
    color: Color(0xFF3B82F6),
  ),
  PreferredColorOption(
    key: 'indigo',
    label: 'Indigo',
    color: Color(0xFF6366F1),
  ),
  PreferredColorOption(
    key: 'violet',
    label: 'Violet',
    color: Color(0xFF8B5CF6),
  ),
  PreferredColorOption(
    key: 'purple',
    label: 'Purple',
    color: Color(0xFFA855F7),
  ),
  PreferredColorOption(
    key: 'pink',
    label: 'Pink',
    color: Color(0xFFEC4899),
  ),
  PreferredColorOption(
    key: 'rose',
    label: 'Rose',
    color: Color(0xFFF43F5E),
  ),
  PreferredColorOption(
    key: 'red',
    label: 'Red',
    color: Color(0xFFEF4444),
  ),
  PreferredColorOption(
    key: 'orange',
    label: 'Orange',
    color: Color(0xFFF97316),
  ),
  PreferredColorOption(
    key: 'amber',
    label: 'Amber',
    color: Color(0xFFF59E0B),
  ),
  PreferredColorOption(
    key: 'emerald',
    label: 'Emerald',
    color: Color(0xFF10B981),
  ),
  PreferredColorOption(
    key: 'teal',
    label: 'Teal',
    color: Color(0xFF14B8A6),
  ),
  PreferredColorOption(
    key: 'cyan',
    label: 'Cyan',
    color: Color(0xFF06B6D4),
  ),
];

class AppColorSchemeState {
  final ColorSchemeSource source;
  final Color preferredColor;
  final String preferredColorName;

  const AppColorSchemeState({
    this.source = ColorSchemeSource.materialYou,
    this.preferredColor = const Color(0xFF18181B),
    this.preferredColorName = 'Slate',
  });

  bool get isMaterialYou => source == ColorSchemeSource.materialYou;

  AppColorSchemeState copyWith({
    ColorSchemeSource? source,
    Color? preferredColor,
    String? preferredColorName,
  }) {
    return AppColorSchemeState(
      source: source ?? this.source,
      preferredColor: preferredColor ?? this.preferredColor,
      preferredColorName: preferredColorName ?? this.preferredColorName,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppColorSchemeState &&
        other.source == source &&
        other.preferredColor.toARGB32() == preferredColor.toARGB32() &&
        other.preferredColorName == preferredColorName;
  }

  @override
  int get hashCode => Object.hash(
        source,
        preferredColor.toARGB32(),
        preferredColorName,
      );
}

class AppColorSchemeNotifier extends StateNotifier<AppColorSchemeState> {
  final FlutterSecureStorage _storage;
  static const String sourceKey = 'app_color_scheme_source';
  static const String preferredColorKey = 'app_preferred_color_hex';
  static const String preferredColorNameKey = 'app_preferred_color_name';

  AppColorSchemeNotifier([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage(),
        super(const AppColorSchemeState()) {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    try {
      final savedSource = await _storage.read(key: sourceKey);
      final savedHex = await _storage.read(key: preferredColorKey);
      final savedName = await _storage.read(key: preferredColorNameKey);

      ColorSchemeSource source = state.source;
      if (savedSource == 'preferred') {
        source = ColorSchemeSource.preferred;
      } else if (savedSource == 'materialYou' || savedSource == 'material_you') {
        source = ColorSchemeSource.materialYou;
      }

      Color color = state.preferredColor;
      if (savedHex != null) {
        final parsed = parseHexColor(savedHex);
        if (parsed != null) color = parsed;
      }

      String name = state.preferredColorName;
      if (savedName != null && savedName.isNotEmpty) {
        name = savedName;
      }

      state = AppColorSchemeState(
        source: source,
        preferredColor: color,
        preferredColorName: name,
      );
    } catch (_) {}
  }

  Future<void> setSource(ColorSchemeSource source) async {
    state = state.copyWith(source: source);
    try {
      await _storage.write(key: sourceKey, value: source.name);
    } catch (_) {}
  }

  Future<void> setMaterialYou() async {
    await setSource(ColorSchemeSource.materialYou);
  }

  Future<void> setPreferredColor(Color color, String name) async {
    state = state.copyWith(
      source: ColorSchemeSource.preferred,
      preferredColor: color,
      preferredColorName: name,
    );
    try {
      await _storage.write(
        key: sourceKey,
        value: ColorSchemeSource.preferred.name,
      );
      await _storage.write(
        key: preferredColorKey,
        value: '#${(color.toARGB32() & 0x00FFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}',
      );
      await _storage.write(key: preferredColorNameKey, value: name);
    } catch (_) {}
  }
}

final appColorSchemeProvider =
    StateNotifierProvider<AppColorSchemeNotifier, AppColorSchemeState>((ref) {
  final storage = ref.watch(themeStorageProvider);
  return AppColorSchemeNotifier(storage);
});

final colorSchemePreferenceProvider = appColorSchemeProvider;
