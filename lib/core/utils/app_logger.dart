import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

typedef LogOutputHandler = void Function(
  LogLevel level,
  String message, {
  required String tag,
  Object? error,
  StackTrace? stackTrace,
});

/// Central logging utility for the client application.
class AppLogger {
  const AppLogger._();

  /// Optional custom handler (useful for testing or attaching third-party telemetry).
  @visibleForTesting
  static LogOutputHandler? customHandler;

  static void debug(
    String message, {
    String tag = 'APP',
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode || customHandler != null) {
      _log(LogLevel.debug, message, tag: tag, error: error, stackTrace: stackTrace);
    }
  }

  static void info(
    String message, {
    String tag = 'APP',
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.info, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  static void warning(
    String message, {
    String tag = 'APP',
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.warning, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  static void error(
    String message, {
    String tag = 'APP',
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.error, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  static void _log(
    LogLevel level,
    String message, {
    required String tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (customHandler != null) {
      customHandler!(level, message, tag: tag, error: error, stackTrace: stackTrace);
      return;
    }

    final levelCode = switch (level) {
      LogLevel.debug => 500,
      LogLevel.info => 800,
      LogLevel.warning => 900,
      LogLevel.error => 1000,
    };

    final prefix = switch (level) {
      LogLevel.debug => '[DEBUG]',
      LogLevel.info => '[INFO]',
      LogLevel.warning => '[WARN]',
      LogLevel.error => '[ERROR]',
    };

    developer.log(
      '$prefix [$tag] $message',
      name: 'lockmyslot.$tag',
      level: levelCode,
      error: error,
      stackTrace: stackTrace,
    );

    if (kDebugMode) {
      final errStr = error != null ? '\nError: $error' : '';
      final stackStr = stackTrace != null ? '\nStack: $stackTrace' : '';
      debugPrint('$prefix [$tag] $message$errStr$stackStr');
    }
  }
}
