// lib/exceptions/request_timeout_exception.dart

import 'api_exception.dart';

/// No response arrived in time. The server may still have processed the
/// request, so writes must be retried with the same idempotency key.
class RequestTimeoutException extends ApiException {
  /// Creates the exception.
  const RequestTimeoutException([super.message = 'The request timed out']);

  @override
  bool get isRetryable => true;
}
