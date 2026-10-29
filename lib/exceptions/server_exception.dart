// lib/exceptions/server_exception.dart

import 'api_exception.dart';

/// The server answered with an unexpected error status.
class ServerException extends ApiException {
  /// Creates the exception.
  const ServerException(this.statusCode, [super.message = 'Server error']);

  /// HTTP status code.
  final int statusCode;

  @override
  bool get isRetryable => statusCode >= 500;

  @override
  String toString() => 'ServerException($statusCode): $message';
}
