import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/support/auth_test_helpers.dart';

export '../features/auth/support/auth_test_helpers.dart';

/// Legacy helper — prefer [pumpAuthScreen] / [pumpAuthWidget].
Widget pumpAuthApp({
  required Widget home,
  Locale locale = const Locale('en'),
  List<Override>? overrides,
}) {
  return pumpAuthScreen(home: home, locale: locale, overrides: overrides);
}
