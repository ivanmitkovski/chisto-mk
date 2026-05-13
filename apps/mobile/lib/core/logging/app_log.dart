import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Lightweight logging: verbose/debug only in debug builds; warnings/errors always.
class AppLog {
  AppLog._();

  static const String _name = 'chisto';

  static void verbose(String message, {Object? error, StackTrace? stackTrace}) {
    if (!kDebugMode) {
      return;
    }
    developer.log(message, name: _name, level: 500, error: error, stackTrace: stackTrace);
  }

  static void warn(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(message, name: _name, level: 900, error: error, stackTrace: stackTrace);
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(message, name: _name, level: 1000, error: error, stackTrace: stackTrace);
  }
}
