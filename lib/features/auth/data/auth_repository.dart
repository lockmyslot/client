import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/storage/secure_storage.dart';
import 'models/user.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final SecureStorageService _storage;

  AuthRepository(this._apiClient, this._storage);

  Future<User> register({
    required String displayName,
    String? username,
    String? password,
  }) async {
    final body = <String, dynamic>{
      'display_name': displayName,
      if (username != null && username.isNotEmpty) 'username': username,
      if (password != null && password.isNotEmpty) 'password': password,
    };

    final response = await _apiClient.post<dynamic>(
      ApiConstants.register,
      body: body,
    );

    return _parseAuthResponse(response.data);
  }

  Future<User> login({
    required String username,
    required String password,
  }) async {
    final response = await _apiClient.post<dynamic>(
      ApiConstants.login,
      body: {
        'username': username,
        'password': password,
      },
    );

    return _parseAuthResponse(response.data);
  }

  Future<User> _parseAuthResponse(dynamic rawData) async {
    User user;
    String? token;

    if (rawData is Map<String, dynamic>) {
      if (rawData.containsKey('user')) {
        user = User.fromJson(rawData['user'] as Map<String, dynamic>);
        token = rawData['auth_token'] as String? ?? user.authToken;
      } else {
        user = User.fromJson(rawData);
        token = user.authToken;
      }
    } else {
      throw Exception('Invalid auth response structure');
    }

    if (token != null && token.isNotEmpty) {
      await _storage.saveAuthToken(token);
      await _storage.saveUserInfo(
        id: user.id,
        displayName: user.displayName,
        username: user.username,
      );
    }

    return user;
  }

  Future<User> getMe() async {
    final response = await _apiClient.get<User>(
      ApiConstants.me,
      fromJson: (json) => User.fromJson(json as Map<String, dynamic>),
    );
    final user = response.data;
    await _storage.saveUserInfo(
      id: user.id,
      displayName: user.displayName,
      username: user.username,
    );
    return user;
  }

  Future<User> updateMe(String displayName) async {
    final response = await _apiClient.patch<User>(
      ApiConstants.me,
      body: {'display_name': displayName},
      fromJson: (json) => User.fromJson(json as Map<String, dynamic>),
    );
    final user = response.data;
    await _storage.saveUserInfo(
      id: user.id,
      displayName: user.displayName,
      username: user.username,
    );
    return user;
  }

  Future<void> logout() async {
    await _storage.clearAll();
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(secureStorageProvider),
  );
});
