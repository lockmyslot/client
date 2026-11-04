import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockmyslot_app/core/theme/item_color_provider.dart';

class InMemorySecureStorage extends FlutterSecureStorage {
  final Map<String, String> _data = {};

  InMemorySecureStorage([Map<String, String>? initial]) {
    if (initial != null) _data.addAll(initial);
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
}

void main() {
  group('ItemColorPreferenceNotifier Tests', () {
    test('defaults to true when no saved preference exists', () {
      final storage = InMemorySecureStorage();
      final notifier = ItemColorPreferenceNotifier(storage);

      expect(notifier.state, isTrue);
    });

    test('loads false from storage when saved as "false"', () async {
      final storage = InMemorySecureStorage({
        ItemColorPreferenceNotifier.storageKey: 'false',
      });
      final notifier = ItemColorPreferenceNotifier(storage);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(notifier.state, isFalse);
    });

    test('setUseItemColors updates state and saves to storage', () async {
      final storage = InMemorySecureStorage();
      final notifier = ItemColorPreferenceNotifier(storage);

      await notifier.setUseItemColors(false);
      expect(notifier.state, isFalse);
      expect(
        await storage.read(key: ItemColorPreferenceNotifier.storageKey),
        equals('false'),
      );

      await notifier.setUseItemColors(true);
      expect(notifier.state, isTrue);
      expect(
        await storage.read(key: ItemColorPreferenceNotifier.storageKey),
        equals('true'),
      );
    });

    test('toggle flips the preference state', () async {
      final storage = InMemorySecureStorage();
      final notifier = ItemColorPreferenceNotifier(storage);

      expect(notifier.state, isTrue);
      await notifier.toggle();
      expect(notifier.state, isFalse);
      await notifier.toggle();
      expect(notifier.state, isTrue);
    });

    test('ProviderContainer exposes itemColorPreferenceProvider correctly', () async {
      final storage = InMemorySecureStorage();
      final container = ProviderContainer(
        overrides: [
          itemColorPreferenceProvider.overrideWith(
            (ref) => ItemColorPreferenceNotifier(storage),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(itemColorPreferenceProvider), isTrue);
      await container.read(itemColorPreferenceProvider.notifier).setUseItemColors(false);
      expect(container.read(itemColorPreferenceProvider), isFalse);
    });
  });
}
