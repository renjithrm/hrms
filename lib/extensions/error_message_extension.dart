// lib/extensions/error_message_extension.dart

import '../constants/app_strings.dart';
import '../exceptions/api_exception.dart';
import '../exceptions/offline_exception.dart';
import '../exceptions/request_timeout_exception.dart';
import '../exceptions/server_exception.dart';

/// Turns any caught error into a sentence a person can act on.
extension ErrorMessageExtension on Object {
  /// User-facing message for this error.
  String get userMessage => switch (this) {
        OfflineException() => AppStrings.offline,
        RequestTimeoutException() => AppStrings.timeout,
        ServerException(:final statusCode) => AppStrings.serverError(
            statusCode,
          ),
        ApiException(:final message) => message,
        _ => AppStrings.unexpectedError,
      };
}
