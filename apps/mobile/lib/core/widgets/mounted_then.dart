import 'package:flutter/material.dart';

/// Runs [callback] only when [state] is still mounted (Wave 14).
void mountedThen<T>(State state, Future<T> future, void Function(T value) callback) {
  future.then((T value) {
    if (state.mounted) {
      callback(value);
    }
  });
}

void mountedThenVoid(State state, Future<void> future, VoidCallback callback) {
  future.then((_) {
    if (state.mounted) {
      callback();
    }
  });
}
