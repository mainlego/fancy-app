import 'dart:collection';
import 'package:flutter/foundation.dart';

/// Debug logger service that stores logs in memory for display in debug panel
class DebugLogger {
  static final DebugLogger _instance = DebugLogger._internal();
  factory DebugLogger() => _instance;
  DebugLogger._internal();

  static const int _maxLogs = 500;
  final _logs = Queue<LogEntry>();
  final _listeners = <VoidCallback>[];

  /// Get all logs
  List<LogEntry> get logs => _logs.toList();

  /// Get logs as string
  String get logsAsString => _logs.map((e) => e.toString()).join('\n');

  /// Add a log entry
  void log(String message, {LogLevel level = LogLevel.info, String? tag}) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      message: message,
      level: level,
      tag: tag,
    );

    _logs.addFirst(entry);

    // Keep only last N logs
    while (_logs.length > _maxLogs) {
      _logs.removeLast();
    }

    // Also print to console
    debugPrint('[${entry.levelIcon}${tag != null ? ' $tag' : ''}] $message');

    // Notify listeners
    for (final listener in _listeners) {
      listener();
    }
  }

  /// Log info
  void info(String message, {String? tag}) => log(message, level: LogLevel.info, tag: tag);

  /// Log warning
  void warn(String message, {String? tag}) => log(message, level: LogLevel.warning, tag: tag);

  /// Log error
  void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    var fullMessage = message;
    if (error != null) {
      fullMessage += '\nError: $error';
    }
    if (stackTrace != null) {
      fullMessage += '\nStack: $stackTrace';
    }
    log(fullMessage, level: LogLevel.error, tag: tag);
  }

  /// Log debug
  void debug(String message, {String? tag}) => log(message, level: LogLevel.debug, tag: tag);

  /// Clear all logs
  void clear() {
    _logs.clear();
    for (final listener in _listeners) {
      listener();
    }
  }

  /// Add listener for log updates
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  /// Remove listener
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }
}

/// Log levels
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// Single log entry
class LogEntry {
  final DateTime timestamp;
  final String message;
  final LogLevel level;
  final String? tag;

  LogEntry({
    required this.timestamp,
    required this.message,
    required this.level,
    this.tag,
  });

  String get levelIcon {
    switch (level) {
      case LogLevel.debug:
        return '🔍';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
    }
  }

  String get timeString {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    final ms = timestamp.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }

  @override
  String toString() {
    return '[$timeString] $levelIcon${tag != null ? ' [$tag]' : ''} $message';
  }
}

/// Global debug logger instance
final debugLogger = DebugLogger();

/// Shortcut functions
void logDebug(String message, {String? tag}) => debugLogger.debug(message, tag: tag);
void logInfo(String message, {String? tag}) => debugLogger.info(message, tag: tag);
void logWarn(String message, {String? tag}) => debugLogger.warn(message, tag: tag);
void logError(String message, {String? tag, Object? error, StackTrace? stackTrace}) =>
    debugLogger.error(message, tag: tag, error: error, stackTrace: stackTrace);
