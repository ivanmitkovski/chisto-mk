import 'package:flutter/foundation.dart';

/// Prints to the `flutter run` console (unlike [AppLog], which uses
/// `dart:developer` and is often invisible in the terminal).
void chistoSubmitDebugLog(String message, {Object? error, StackTrace? stack}) {
  if (!kDebugMode) {
    return;
  }
  final StringBuffer buf = StringBuffer('[chisto][submit] $message');
  if (error != null) {
    buf.write(' | $error');
  }
  if (stack != null) {
    buf.write('\n$stack');
  }
  debugPrint(buf.toString());
}
