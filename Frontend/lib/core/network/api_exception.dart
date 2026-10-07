import '../error/failures.dart';

/// Raw transport-level error, built from a Dio failure or a parsed
/// backend envelope `{ error: { code, message, details, requestId } }`
/// (see `contracts/common.yaml`).
class ApiException implements Exception {
  final int? statusCode;
  final String? code;
  final String message;
  final List<dynamic> details;

  const ApiException({
    this.statusCode,
    this.code,
    this.message = 'Unknown error',
    this.details = const [],
  });

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}

/// Maps an [ApiException] to the app's [Failure] hierarchy
/// (`lib/core/error/failures.dart`). Repositories throw [Failure],
/// never [ApiException].
Failure apiExceptionToFailure(ApiException e) {
  if (e.code == 'NETWORK_ERROR' || e.statusCode == null) {
    return NetworkFailure(e.message, code: e.code);
  }

  switch (e.code) {
    case 'AUTH_INVALID_CREDENTIALS':
    case 'AUTH_TOKEN_EXPIRED':
    case 'AUTH_TOKEN_INVALID':
    case 'AUTH_REFRESH_REUSED':
    case 'AUTH_EMAIL_NOT_VERIFIED':
    case 'AUTH_ACCOUNT_LOCKED':
    case 'EMAIL_ALREADY_USED':
      return AuthFailure(e.message, code: e.code);
    case 'VALIDATION_ERROR':
      return ValidationFailure(
        e.message,
        code: e.code,
        fieldErrors: _fieldErrors(e.details),
      );
    case 'NOT_FOUND':
      return NotFoundFailure(e.message, code: e.code);
    case 'FORBIDDEN':
    case 'ROLE_ALREADY_ASSIGNED':
      return PermissionFailure(e.message, code: e.code);
    default:
      return ServerFailure(e.message, code: e.code);
  }
}

Map<String, String> _fieldErrors(List<dynamic> details) {
  final errors = <String, String>{};
  for (final item in details) {
    if (item is Map) {
      final path = item['path']?.toString();
      final message = item['message']?.toString();
      if (path != null && path.isNotEmpty && message != null) {
        errors[path] = message;
      }
    }
  }
  return errors;
}
