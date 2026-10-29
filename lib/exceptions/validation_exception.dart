// lib/exceptions/validation_exception.dart

import 'api_exception.dart';

/// The server rejected a submission's content (HTTP 422).
class ValidationException extends ApiException {
  /// Creates the exception.
  const ValidationException({
    required String message,
    this.fieldErrors = const {},
  }) : super(message);

  /// Messages keyed by request field, for example `startDate`.
  final Map<String, String> fieldErrors;

  @override
  bool get isRetryable => false;
}
