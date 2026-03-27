import 'dart:io';

import 'package:flutter/foundation.dart';

/// Lightweight shared state for the current profile avatar.
///
/// This is intentionally simple and UI-focused so that a real backend-driven
/// user/profile service can replace it later without changing the widgets.
class ProfileAvatarState extends ChangeNotifier {
  String? _localPath;
  String? _remoteUrl;

  String? get localPath => _localPath;
  String? get remoteUrl => _remoteUrl;

  File? get localFile => _localPath != null ? File(_localPath!) : null;

  void setLocalPath(String path) {
    if (path == _localPath) return;
    _localPath = path;
    notifyListeners();
  }

  void setRemoteUrl(String? url) {
    if (url == _remoteUrl) return;
    _remoteUrl = url;
    notifyListeners();
  }

  void clearLocalPath() {
    if (_localPath == null) return;
    _localPath = null;
    notifyListeners();
  }
}

final ProfileAvatarState profileAvatarState = ProfileAvatarState();
