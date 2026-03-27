import 'package:flutter/foundation.dart';

class NotificationOpenDiagnostics {
  const NotificationOpenDiagnostics._();

  static int _openAttempts = 0;
  static int _openSuccess = 0;
  static int _openFailure = 0;

  static void recordOpenAttempt(String source) {
    _openAttempts += 1;
    _debug('attempt', source);
  }

  static void recordOpenSuccess(String source) {
    _openSuccess += 1;
    _debug('success', source);
  }

  static void recordOpenFailure(String source) {
    _openFailure += 1;
    _debug('failure', source);
  }

  static String summary() {
    return '[NotifOpen] attempts=$_openAttempts success=$_openSuccess failure=$_openFailure';
  }

  static void _debug(String event, String source) {
    if (!kDebugMode) return;
    debugPrint('${summary()} event=$event source=$source');
  }
}
