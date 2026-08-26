import 'dart:developer' as dev;

/// Lightweight logging utility for Hikmah Player.
///
/// Wraps `dart:developer` [log] so every call site stays consistent and
/// can be toggled or redirected without touching calling code.
class AppLogger {
  AppLogger._();

  static const String _defaultName = 'HikmahPlayer';

  static void info(String message, {String? name}) {
    dev.log(message, name: name ?? _defaultName, level: 800);
  }

  static void warning(String message, {String? name}) {
    dev.log(message, name: name ?? _defaultName, level: 900);
  }

  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? name,
  }) {
    dev.log(
      message,
      name: name ?? _defaultName,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void debug(String message, {String? name}) {
    dev.log(message, name: name ?? _defaultName, level: 500);
  }
}

/// Top-level convenience helpers so call sites stay short.
void logInfo(String message) => AppLogger.info(message);
void logWarning(String message) => AppLogger.warning(message);
void logError(String message, [Object? error, StackTrace? stackTrace]) =>
    AppLogger.error(message, error: error, stackTrace: stackTrace);
void logDebug(String message) => AppLogger.debug(message);
