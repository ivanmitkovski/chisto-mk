import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Restores OTP [FocusNode] focus and re-shows the Android IME after dismissal.
Future<void> ensureOtpKeyboardVisible(FocusNode node) async {
  if (!node.canRequestFocus) return;
  if (!node.hasFocus) {
    node.requestFocus();
  }
  if (defaultTargetPlatform == TargetPlatform.android) {
    await SystemChannels.textInput.invokeMethod<void>('TextInput.show');
  }
}
