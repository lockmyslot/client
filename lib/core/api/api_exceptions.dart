abstract class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException([
    String message = 'Unauthorized. Please register or log in again.',
  ]) : super(message, 401);
}

class ForbiddenException extends ApiException {
  const ForbiddenException([
    String message =
        'Access forbidden. You do not have permissions for this action.',
  ]) : super(message, 403);
}

class NotFoundException extends ApiException {
  const NotFoundException([String message = 'Resource not found.'])
    : super(message, 404);
}

class ConflictException extends ApiException {
  const ConflictException([
    String message =
        'Conflict detected. The requested resource or slot is unavailable.',
  ]) : super(message, 409);
}

class ValidationException extends ApiException {
  final List<String> violations;

  const ValidationException(String message, {this.violations = const []})
    : super(message, 400);

  @override
  String toString() {
    if (violations.isNotEmpty) {
      return '$message\n- ${violations.join('\n- ')}';
    }
    return message;
  }
}

class NetworkException extends ApiException {
  const NetworkException([
    super.message =
        'Network connection failed. Please check your internet connection.',
  ]);
}

class OfflineException extends ApiException {
  const OfflineException([
    super.message =
        'You appear to be offline. No cached data is available for this resource.',
  ]);
}

class ServerException extends ApiException {
  const ServerException([
    super.message = 'An unexpected server error occurred.',
    super.statusCode,
  ]);
}
