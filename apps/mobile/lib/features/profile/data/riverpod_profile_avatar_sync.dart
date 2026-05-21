import 'package:chisto_mobile/core/profile/profile_avatar_sync.dart';
import 'package:chisto_mobile/features/profile/presentation/providers/profile_avatar_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RiverpodProfileAvatarSync implements ProfileAvatarSync {
  RiverpodProfileAvatarSync(this._container);

  final ProviderContainer _container;

  @override
  void setRemoteUrl(String? remoteUrl) {
    _container
        .read(profileAvatarNotifierProvider.notifier)
        .setRemoteUrl(remoteUrl);
  }

  @override
  void clearAll() {
    _container.read(profileAvatarNotifierProvider.notifier).clearAll();
  }
}
