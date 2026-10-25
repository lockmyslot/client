import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lockmyslot_app/core/theme/theme_provider.dart';

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
  group('ThemeModeNotifier', () {
    test('defaults to ThemeMode.system when storage is empty', () async {
      final storage = FakeFlutterSecureStorage();
      final notifier = ThemeModeNotifier(storage);

      expect(notifier.state, ThemeMode.system);
    });

    test('loads saved dark mode from storage', () async {
      final storage = FakeFlutterSecureStorage({
        ThemeModeNotifier.themeModeKey: 'dark',
      });
      final notifier = ThemeModeNotifier(storage);

      // Allow async _loadThemeMode to complete
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state, ThemeMode.dark);
    });

    test('loads saved light mode from storage', () async {
      final storage = FakeFlutterSecureStorage({
        ThemeModeNotifier.themeModeKey: 'light',
      });
      final notifier = ThemeModeNotifier(storage);

      await Future<void>.delayed(Duration.zero);

      expect(notifier.state, ThemeMode.light);
    });

    test('setThemeMode updates state and writes to storage', () async {
      final storage = FakeFlutterSecureStorage();
      final notifier = ThemeModeNotifier(storage);

      await notifier.setThemeMode(ThemeMode.dark);
      expect(notifier.state, ThemeMode.dark);
      expect(await storage.read(key: ThemeModeNotifier.themeModeKey), 'dark');

      await notifier.setThemeMode(ThemeMode.light);
      expect(notifier.state, ThemeMode.light);
      expect(await storage.read(key: ThemeModeNotifier.themeModeKey), 'light');

      await notifier.setThemeMode(ThemeMode.system);
      expect(notifier.state, ThemeMode.system);
      expect(await storage.read(key: ThemeModeNotifier.themeModeKey), 'system');
    });

    test('ThemeModeDisplay extension provides correct title and description', () {
      expect(ThemeMode.system.title, 'System default');
      expect(ThemeMode.light.title, 'Light');
      expect(ThemeMode.dark.title, 'Dark');

      expect(ThemeMode.system.description.isNotEmpty, true);
      expect(ThemeMode.light.description.isNotEmpty, true);
      expect(ThemeMode.dark.description.isNotEmpty, true);

      expect(ThemeMode.system.icon, Icons.brightness_auto_outlined);
      expect(ThemeMode.light.icon, Icons.light_mode_outlined);
      expect(ThemeMode.dark.icon, Icons.dark_mode_outlined);
    });
  });
}
