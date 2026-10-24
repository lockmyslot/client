import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../data/models/user.dart';
import '../../../core/api/api_exceptions.dart';
import '../../../core/storage/secure_storage.dart';

class AuthState {
  final User? user;
  final bool isAuthenticated;
  final bool isLoading;
  final bool isInitialized;
  final String? error;

  const AuthState({
    this.user,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.isInitialized = false,
    this.error,
  });

  AuthState copyWith({
    User? user,
    bool? isAuthenticated,
    bool? isLoading,
    bool? isInitialized,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final SecureStorageService _storage;

  AuthNotifier(this._repository, this._storage)
    : super(const AuthState(isLoading: true, isInitialized: false)) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final token = await _storage.getAuthToken();
      if (token == null || token.isEmpty) {
        state = const AuthState(
          isAuthenticated: false,
          isLoading: false,
          isInitialized: true,
        );
        return;
      }

      final user = await _repository.getMe();
      state = AuthState(
        user: user,
        isAuthenticated: true,
        isLoading: false,
        isInitialized: true,
      );
    } catch (e) {
      if (e is UnauthorizedException) {
        // If explicitly unauthorized (401), the token is invalid; clear it
        await _storage.deleteAuthToken();
        state = const AuthState(
          isAuthenticated: false,
          isLoading: false,
          isInitialized: true,
        );
      } else {
        // If network/server error, fallback to cached user credentials if available
        final savedId = await _storage.getUserId();
        final savedName = await _storage.getUserDisplayName();
        final savedUsername = await _storage.getUsername();
        if (savedId != null && savedName != null) {
          state = AuthState(
            user: User(
              id: savedId,
              username: savedUsername,
              displayName: savedName,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            isAuthenticated: true,
            isLoading: false,
            isInitialized: true,
          );
        } else {
          state = const AuthState(
            isAuthenticated: false,
            isLoading: false,
            isInitialized: true,
          );
        }
      }
    }
  }

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repository.login(
        username: username,
        password: password,
      );
      state = AuthState(
        user: user,
        isAuthenticated: true,
        isLoading: false,
        isInitialized: true,
      );
      return true;
    } catch (e) {
      final message = e is ApiException
          ? e.message
          : e.toString().replaceAll('Exception: ', '');
      state = state.copyWith(isLoading: false, error: message);
      return false;
    }
  }

  Future<bool> register({
    required String displayName,
    String? username,
    String? password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repository.register(
        displayName: displayName,
        username: username,
        password: password,
      );
      state = AuthState(
        user: user,
        isAuthenticated: true,
        isLoading: false,
        isInitialized: true,
      );
      return true;
    } catch (e) {
      final message = e is ApiException
          ? e.message
          : e.toString().replaceAll('Exception: ', '');
      state = state.copyWith(isLoading: false, error: message);
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _repository.logout();
    state = const AuthState(
      isAuthenticated: false,
      isLoading: false,
      isInitialized: true,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthNotifier(repo, storage);
});
