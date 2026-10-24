import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../storage/secure_storage.dart';
import 'api_exceptions.dart';
import 'api_response.dart';

class ApiClient {
  final String baseUrl;
  final SecureStorageService storage;
  final http.Client _client;

  ApiClient({String? baseUrl, required this.storage, http.Client? client})
    : baseUrl = baseUrl ?? ApiConstants.baseUrl,
      _client = client ?? http.Client();

  Future<Map<String, String>> _getHeaders([
    Map<String, String>? extraHeaders,
  ]) async {
    final token = await storage.getAuthToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
      headers['x-auth-token'] = token;
    }
    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }
    return headers;
  }

  Uri _buildUri(String path, [Map<String, dynamic>? query]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '$baseUrl$cleanPath';
    final baseUri = Uri.parse(fullUrl);
    if (query == null || query.isEmpty) {
      return baseUri;
    }

    final queryParams = <String, String>{};
    query.forEach((key, value) {
      if (value != null) {
        queryParams[key] = value.toString();
      }
    });
    return baseUri.replace(queryParameters: queryParams);
  }

  Future<http.Response> _sendWithRetry(
    Future<http.Response> Function(http.Client client) requestFn,
  ) async {
    try {
      return await requestFn(_client);
    } catch (e) {
      if (e is http.ClientException ||
          e.toString().contains('Connection closed')) {
        final freshClient = http.Client();
        try {
          return await requestFn(freshClient);
        } finally {
          freshClient.close();
        }
      }
      rethrow;
    }
  }

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? query,
    T Function(dynamic json)? fromJson,
  }) async {
    final http.Response response;
    try {
      final uri = _buildUri(path, query);
      final headers = await _getHeaders();
      response = await _sendWithRetry(
        (client) => client.get(uri, headers: headers),
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw NetworkException(e.toString());
    }
    return _processResponse<T>(response, fromJson);
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic body,
    T Function(dynamic json)? fromJson,
  }) async {
    final http.Response response;
    try {
      final uri = _buildUri(path);
      final headers = await _getHeaders();
      final encodedBody = body != null ? jsonEncode(body) : null;
      response = await _sendWithRetry(
        (client) => client.post(uri, headers: headers, body: encodedBody),
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw NetworkException(e.toString());
    }
    return _processResponse<T>(response, fromJson);
  }

  Future<ApiResponse<T>> patch<T>(
    String path, {
    dynamic body,
    T Function(dynamic json)? fromJson,
  }) async {
    final http.Response response;
    try {
      final uri = _buildUri(path);
      final headers = await _getHeaders();
      final encodedBody = body != null ? jsonEncode(body) : null;
      response = await _sendWithRetry(
        (client) => client.patch(uri, headers: headers, body: encodedBody),
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw NetworkException(e.toString());
    }
    return _processResponse<T>(response, fromJson);
  }

  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic body,
    T Function(dynamic json)? fromJson,
  }) async {
    final http.Response response;
    try {
      final uri = _buildUri(path);
      final headers = await _getHeaders();
      final encodedBody = body != null ? jsonEncode(body) : null;
      response = await _sendWithRetry(
        (client) => client.put(uri, headers: headers, body: encodedBody),
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw NetworkException(e.toString());
    }
    return _processResponse<T>(response, fromJson);
  }

  Future<void> delete(String path) async {
    final http.Response response;
    try {
      final uri = _buildUri(path);
      final headers = await _getHeaders();
      response = await _sendWithRetry(
        (client) => client.delete(uri, headers: headers),
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw NetworkException(e.toString());
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    throw _handleError(response);
  }

  ApiResponse<T> _processResponse<T>(
    http.Response response,
    T Function(dynamic json)? fromJson,
  ) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return ApiResponse<T>(data: null as T);
      }
      final decoded = jsonDecode(response.body);
      if (fromJson != null) {
        if (decoded is Map<String, dynamic>) {
          return ApiResponse<T>.fromJson(decoded, fromJson);
        } else {
          return ApiResponse<T>(data: fromJson(decoded));
        }
      } else {
        final data = decoded is Map && decoded.containsKey('data')
            ? decoded['data']
            : decoded;
        return ApiResponse<T>(
          data: data as T,
          meta: decoded is Map && decoded.containsKey('meta')
              ? decoded['meta']
              : null,
        );
      }
    }
    throw _handleError(response);
  }

  ApiException _handleError(http.Response response) {
    String? message;
    List<String> violations = [];

    try {
      if (response.body.isNotEmpty) {
        final json = jsonDecode(response.body);
        if (json is Map) {
          final errorObj = json['error'];
          if (errorObj is Map) {
            message = errorObj['message']?.toString();
            if (errorObj['details'] is List) {
              violations = (errorObj['details'] as List)
                  .map((e) => e.toString())
                  .toList();
            }
          } else if (errorObj is String) {
            message = errorObj;
          } else {
            message = json['message']?.toString();
          }
          if (json['violations'] is List) {
            violations = (json['violations'] as List)
                .map((e) => e.toString())
                .toList();
          } else if (json['errors'] is List) {
            violations = (json['errors'] as List)
                .map((e) => e.toString())
                .toList();
          }
        }
      }
    } catch (_) {}

    switch (response.statusCode) {
      case 400:
        return ValidationException(
          message ?? 'Validation failed.',
          violations: violations,
        );
      case 401:
        return message != null
            ? UnauthorizedException(message)
            : const UnauthorizedException();
      case 403:
        return message != null
            ? ForbiddenException(message)
            : const ForbiddenException();
      case 404:
        return message != null
            ? NotFoundException(message)
            : const NotFoundException();
      case 409:
        return message != null
            ? ConflictException(message)
            : const ConflictException();
      default:
        return ServerException(
          message ?? 'An unexpected server error occurred.',
          response.statusCode,
        );
    }
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return ApiClient(storage: storage);
});
