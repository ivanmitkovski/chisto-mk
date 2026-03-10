import 'dart:io';

import 'package:flutter/foundation.dart';

/// Lightweight shared state for the current profile avatar.
///
/// This is intentionally simple and UI-focused so that a real backend-driven
/// user/profile service can replace it later without changing the widgets.
class ProfileAvatarState extends ChangeNotifier {
  String? _localPath;

  String? get localPath => _localPath;

  File? get localFile => _localPath != null ? File(_localPath!) : null;

  void setLocalPath(String path) {
    if (path == _localPath) return;
    _localPath = path;
    notifyListeners();
  }
}

final ProfileAvatarState profileAvatarState = ProfileAvatarState();

