import 'package:flutter/material.dart';

/// Allows `part` / extension files to trigger rebuilds without calling protected [State.setState].
mixin StateRebuildMixin<T extends StatefulWidget> on State<T> {
  void rebuildState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }
}
