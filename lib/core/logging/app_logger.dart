import 'dart:developer' as developer;

enum LogLevel { debug, info, warning, error }

/// Thin logging boundary so features depend on this interface, not directly
/// on `dart:developer` or a specific logging package.
abstract class AppLogger {
  void debug(String message, {String? tag});
  void info(String message, {String? tag});
  void warning(String message, {String? tag});
  void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  });
}

class DeveloperLogAppLogger implements AppLogger {
  const DeveloperLogAppLogger();

  @override
  void debug(String message, {String? tag}) =>
      _log(LogLevel.debug, message, tag: tag);

  @override
  void info(String message, {String? tag}) =>
      _log(LogLevel.info, message, tag: tag);

  @override
  void warning(String message, {String? tag}) =>
      _log(LogLevel.warning, message, tag: tag);

  @override
  void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      LogLevel.error,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void _log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: tag ?? 'kp_pos',
      level: _severity(level),
      error: error,
      stackTrace: stackTrace,
    );
  }

  int _severity(LogLevel level) => switch (level) {
    LogLevel.debug => 500,
    LogLevel.info => 800,
    LogLevel.warning => 900,
    LogLevel.error => 1000,
  };
}
