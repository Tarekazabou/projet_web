import 'package:flutter/foundation.dart';

/// A simple logger utility that only prints in debug mode
class AppLogger {
  static const String _tag = 'Mealy';

  /// Log debug information
  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      print('[$_tag${tag != null ? '/$tag' : ''}] 🐛 $message');
    }
  }

  /// Log info messages
  static void info(String message, {String? tag}) {
    if (kDebugMode) {
      print('[$_tag${tag != null ? '/$tag' : ''}] ℹ️ $message');
    }
  }

  /// Log success messages
  static void success(String message, {String? tag}) {
    if (kDebugMode) {
      print('[$_tag${tag != null ? '/$tag' : ''}] ✅ $message');
    }
  }

  /// Log warning messages
  static void warning(String message, {String? tag}) {
    if (kDebugMode) {
      print('[$_tag${tag != null ? '/$tag' : ''}] ⚠️ $message');
    }
  }

  /// Log error messages
  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      print('[$_tag${tag != null ? '/$tag' : ''}] ❌ $message');
      if (error != null) {
        print('Error: $error');
      }
      if (stackTrace != null) {
        print('StackTrace: $stackTrace');
      }
    }
  }

  /// Log API request
  static void apiRequest(
    String method,
    String url, {
    Map<String, dynamic>? body,
  }) {
    if (kDebugMode) {
      print('[$_tag/API] 📤 $method $url');
      if (body != null) {
        print('[$_tag/API] Body: $body');
      }
    }
  }

  /// Log API response
  static void apiResponse(int statusCode, String url, {String? body}) {
    if (kDebugMode) {
      print('[$_tag/API] 📥 $statusCode $url');
      if (body != null && body.length < 500) {
        print('[$_tag/API] Response: $body');
      }
    }
  }
}
