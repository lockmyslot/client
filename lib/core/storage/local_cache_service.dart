import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalCacheService {
  final FlutterSecureStorage _storage;
  final Map<String, String> _memoryCache = {};

  static const String _cacheKeyPrefix = 'cache_';

  LocalCacheService([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  String _storageKey(String key) => '$_cacheKeyPrefix$key';

  /// Caches a single object/map by key.
  Future<void> set(String key, dynamic data) async {
    try {
      final jsonString = jsonEncode(data);
      _memoryCache[key] = jsonString;
      await _storage.write(key: _storageKey(key), value: jsonString);
    } catch (_) {
      // Ignore cache write errors to avoid blocking the main flow
    }
  }

  /// Retrieves and deserializes a single cached object.
  Future<T?> get<T>(String key, T Function(dynamic json) fromJson) async {
    try {
      String? jsonString = _memoryCache[key];
      if (jsonString == null) {
        jsonString = await _storage.read(key: _storageKey(key));
        if (jsonString != null) {
          _memoryCache[key] = jsonString;
        }
      }

      if (jsonString == null || jsonString.isEmpty) {
        return null;
      }

      final decoded = jsonDecode(jsonString);
      return fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  /// Caches a list of items by key.
  Future<void> setList(String key, List<dynamic> list) async {
    try {
      final jsonString = jsonEncode(list);
      _memoryCache[key] = jsonString;
      await _storage.write(key: _storageKey(key), value: jsonString);
    } catch (_) {
      // Ignore cache write errors
    }
  }

  /// Retrieves and deserializes a cached list of objects.
  Future<List<T>?> getList<T>(
    String key,
    T Function(dynamic json) fromJson,
  ) async {
    try {
      String? jsonString = _memoryCache[key];
      if (jsonString == null) {
        jsonString = await _storage.read(key: _storageKey(key));
        if (jsonString != null) {
          _memoryCache[key] = jsonString;
        }
      }

      if (jsonString == null || jsonString.isEmpty) {
        return null;
      }

      final decoded = jsonDecode(jsonString);
      if (decoded is List) {
        return decoded.map((e) => fromJson(e)).toList();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Deletes a cached entry by key.
  Future<void> remove(String key) async {
    _memoryCache.remove(key);
    try {
      await _storage.delete(key: _storageKey(key));
    } catch (_) {}
  }

  /// Clears in-memory and persistent cache.
  Future<void> clear() async {
    _memoryCache.clear();
  }
}

final localCacheServiceProvider = Provider<LocalCacheService>((ref) {
  return LocalCacheService();
});
