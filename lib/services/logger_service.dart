// lib/services/logger_service.dart

import 'package:flutter/foundation.dart';

/// Debug logging. Never pass names, coordinates or other personal data;
/// event IDs and status codes are fine.
class LoggerService {
  /// Logs an informational [message] in debug builds.
  void info(String message) {
    if (kDebugMode) debugPrint('[REBS] $message');
  }

  /// Logs an [error] with its [stackTrace] in debug builds.
  ///
  /// Release builds would forward this to remote crash reporting, which is
  /// out of scope for the assignment.
  void error(String context, Object error, [StackTrace? stackTrace]) {
    if (!kDebugMode) return;
    debugPrint('[REBS] $context: $error');
    if (stackTrace != null) debugPrint(stackTrace.toString());
  }
}
