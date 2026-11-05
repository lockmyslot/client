import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lockmyslot_app/core/theme/app_theme.dart';
import 'package:lockmyslot_app/core/theme/color_scheme_provider.dart';

class FakeFlutterSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _data = {};

  FakeFlutterSecureStorage([Map<String, String>? initialData]) {
    if (initialData != null) {
      _data.addAll(initialData);
    }
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _data[key] = value;
    } else {
      _data.remove(key);
    }
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _data[key];
  }
}

void main() {
  group('AppColorSchemeNotifier', () {
    test('defaults to Material You and Slate when storage is empty', () async {
      final storage = FakeFlutterSecureStorage();
      final notifier = AppColorSchemeNotifier(storage);

      expect(notifier.state.source, ColorSchemeSource.materialYou);
      expect(notifier.state.isMaterialYou, isTrue);
      expect(notifier.state.preferredColor, const Color(0xFF18181B));
      expect(notifier.state.preferredColorName, 'Slate');
    });

    test('loads saved preferred color from storage', () async {
      final storage = FakeFlutterSecureStorage({
        AppColorSchemeNotifier.sourceKey: 'preferred',
        AppColorSchemeNotifier.preferredColorKey: '#6366F1',
        AppColorSchemeNotifier.preferredColorNameKey: 'Indigo',
      });
      final notifier = AppColorSchemeNotifier(storage);

      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.source, ColorSchemeSource.preferred);
      expect(notifier.state.isMaterialYou, isFalse);
      expect(notifier.state.preferredColor, const Color(0xFF6366F1));
      expect(notifier.state.preferredColorName, 'Indigo');
    });

    test('setMaterialYou updates source and writes to storage', () async {
      final storage = FakeFlutterSecureStorage({
        AppColorSchemeNotifier.sourceKey: 'preferred',
      });
      final notifier = AppColorSchemeNotifier(storage);
      await Future<void>.delayed(Duration.zero);

      await notifier.setMaterialYou();
      expect(notifier.state.source, ColorSchemeSource.materialYou);
      expect(notifier.state.isMaterialYou, isTrue);
      expect(
        await storage.read(key: AppColorSchemeNotifier.sourceKey),
        'materialYou',
      );
    });

    test('setPreferredColor updates color, source and writes to storage', () async {
      final storage = FakeFlutterSecureStorage();
      final notifier = AppColorSchemeNotifier(storage);

      await notifier.setPreferredColor(const Color(0xFF3B82F6), 'Blue');
      expect(notifier.state.source, ColorSchemeSource.preferred);
      expect(notifier.state.isMaterialYou, isFalse);
      expect(notifier.state.preferredColor, const Color(0xFF3B82F6));
      expect(notifier.state.preferredColorName, 'Blue');

      expect(
        await storage.read(key: AppColorSchemeNotifier.sourceKey),
        'preferred',
      );
      expect(
        await storage.read(key: AppColorSchemeNotifier.preferredColorKey),
        '#3B82F6',
      );
      expect(
        await storage.read(key: AppColorSchemeNotifier.preferredColorNameKey),
        'Blue',
      );
    });
  });

  group('AppTheme.schemeFromSeed', () {
    test('creates light and dark color schemes from preferred seed', () {
      final lightScheme = AppTheme.schemeFromSeed(
        const Color(0xFF6366F1),
        Brightness.light,
      );
      expect(lightScheme.brightness, Brightness.light);

      final darkScheme = AppTheme.schemeFromSeed(
        const Color(0xFF6366F1),
        Brightness.dark,
      );
      expect(darkScheme.brightness, Brightness.dark);
    });
  });
}
