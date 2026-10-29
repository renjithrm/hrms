// lib/exceptions/api_exception.dart

/// Base type for failures talking to the API.
abstract class ApiException implements Exception {
  /// Creates an exception with a developer-facing [message].
  const ApiException(this.message);

  /// What went wrong, for logs. User-facing text comes from `AppStrings`.
  final String message;

  /// Whether retrying the same request later could succeed.
  bool get isRetryable;

  @override
  String toString() => '$runtimeType: $message';
}
