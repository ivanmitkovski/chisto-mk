import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Immutable avatar preview state (local pick vs remote URL).
class ProfileAvatarData {
  const ProfileAvatarData({this.localPath, this.remoteUrl});

  final String? localPath;
  final String? remoteUrl;

  File? get localFile =>
      localPath != null && localPath!.isNotEmpty ? File(localPath!) : null;
}

final profileAvatarNotifierProvider =
    NotifierProvider<ProfileAvatarNotifier, ProfileAvatarData>(
  ProfileAvatarNotifier.new,
);

class ProfileAvatarNotifier extends Notifier<ProfileAvatarData> {
  @override
  ProfileAvatarData build() => const ProfileAvatarData();

  void setLocalPath(String path) {
    if (path == state.localPath) return;
    state = ProfileAvatarData(localPath: path, remoteUrl: state.remoteUrl);
  }

  void setRemoteUrl(String? url) {
    if (url == state.remoteUrl) return;
    state = ProfileAvatarData(localPath: state.localPath, remoteUrl: url);
  }

  void clearLocalPath() {
    if (state.localPath == null) return;
    state = ProfileAvatarData(localPath: null, remoteUrl: state.remoteUrl);
  }

  void clearAll() {
    state = const ProfileAvatarData();
  }
}
