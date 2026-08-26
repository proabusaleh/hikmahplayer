import 'package:logger/logger.dart';

/// Global logger instance.
final appLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 80,
    colors: false,
    printEmojis: false,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
  level: Level.debug, // Raise to Level.warning in production builds.
);

void logDebug(String message) => appLogger.d(message);
void logInfo(String message) => appLogger.i(message);
void logWarning(String message) => appLogger.w(message);
void logError(String message, [dynamic error, StackTrace? stackTrace]) =>
    appLogger.e(message, error: error, stackTrace: stackTrace);
