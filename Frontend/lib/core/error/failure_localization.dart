import 'failures.dart';

/// Maps a [Failure] (with backend stable `code`, see `contracts/common.yaml`)
/// to a localized i18n key usable with `context.tr(key)`.
///
/// Usage:
/// ```dart
/// } on Failure catch (f) {
///   final l10n = failureL10n(f);
///   SnackBar(content: Text(context.tr(l10n.key)));
/// }
/// ```
({String key, Map<String, String> args}) failureL10n(Failure failure) {
  const noArgs = <String, String>{};

  if (failure is NetworkFailure) {
    return (key: 'no_internet', args: noArgs);
  }

  switch (failure.code) {
    case 'AUTH_INVALID_CREDENTIALS':
      return (key: 'invalid_credentials', args: noArgs);
    case 'AUTH_EMAIL_NOT_VERIFIED':
      return (key: 'email_not_verified', args: noArgs);
    case 'AUTH_ACCOUNT_LOCKED':
      return (key: 'account_locked', args: noArgs);
    case 'AUTH_TOKEN_EXPIRED':
    case 'AUTH_TOKEN_INVALID':
    case 'AUTH_REFRESH_REUSED':
      return (key: 'session_expired', args: noArgs);
    case 'EMAIL_ALREADY_USED':
      return (key: 'email_already_exists', args: noArgs);
    case 'INVALID_CODE':
      return (key: 'invalid_code', args: noArgs);
    case 'NOT_FOUND':
      return (key: 'not_found', args: noArgs);
    case 'FORBIDDEN':
      return (key: 'permission_denied', args: noArgs);
    case 'RATE_LIMITED':
      return (key: 'too_many_requests', args: noArgs);
    case 'VALIDATION_ERROR':
      return (key: _validationKey(failure as ValidationFailure), args: noArgs);
    default:
      return (key: 'server_error', args: noArgs);
  }
}

String _validationKey(ValidationFailure failure) {
  for (final entry in failure.fieldErrors.entries) {
    final path = entry.key.toLowerCase();
    if (path.contains('email')) return 'invalid_email';
    if (path.contains('password')) return 'password_too_short';
    if (path.contains('code')) return 'invalid_code';
    if (path.contains('firstname') || path.contains('lastname')) {
      return 'required_field';
    }
  }
  return 'invalid_format';
}
