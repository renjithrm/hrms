// lib/exceptions/offline_exception.dart

import 'api_exception.dart';

/// The request could not reach the server at all.
class OfflineException extends ApiException {
  /// Creates the exception.
  const OfflineException([super.message = 'No connection to the server']);

  @override
  bool get isRetryable => true;
}
