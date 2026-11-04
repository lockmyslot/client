import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'theme_provider.dart';

class ItemColorPreferenceNotifier extends StateNotifier<bool> {
  final FlutterSecureStorage _storage;
  static const String storageKey = 'app_use_item_colors';

  ItemColorPreferenceNotifier([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage(),
        super(true) {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    try {
      final saved = await _storage.read(key: storageKey);
      if (saved != null) {
        state = saved.toLowerCase() == 'true';
      }
    } catch (_) {}
  }

  Future<void> setUseItemColors(bool value) async {
    state = value;
    try {
      await _storage.write(key: storageKey, value: value.toString());
    } catch (_) {}
  }

  Future<void> toggle() async {
    await setUseItemColors(!state);
  }
}

final itemColorPreferenceProvider =
    StateNotifierProvider<ItemColorPreferenceNotifier, bool>((ref) {
  final storage = ref.watch(themeStorageProvider);
  return ItemColorPreferenceNotifier(storage);
});
