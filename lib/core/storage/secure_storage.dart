import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  static const String _authTokenKey = 'auth_token';
  static const String _userDisplayNameKey = 'user_display_name';
  static const String _userIdKey = 'user_id';

  SecureStorageService([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveAuthToken(String token) async {
    await _storage.write(key: _authTokenKey, value: token);
  }

  Future<String?> getAuthToken() async {
    return await _storage.read(key: _authTokenKey);
  }

  Future<void> deleteAuthToken() async {
    await _storage.delete(key: _authTokenKey);
  }

  Future<void> saveUserInfo({required String id, required String displayName}) async {
    await _storage.write(key: _userIdKey, value: id);
    await _storage.write(key: _userDisplayNameKey, value: displayName);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  Future<String?> getUserDisplayName() async {
    return await _storage.read(key: _userDisplayNameKey);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});
