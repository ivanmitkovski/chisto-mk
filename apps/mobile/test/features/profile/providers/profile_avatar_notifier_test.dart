import 'package:chisto_mobile/features/profile/presentation/providers/profile_avatar_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProfileAvatarNotifier', () {
    test('setLocalPath updates state and dedupes identical path', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      final ProfileAvatarNotifier n =
          container.read(profileAvatarNotifierProvider.notifier);
      n.setLocalPath('/tmp/a.jpg');
      expect(container.read(profileAvatarNotifierProvider).localPath,
          '/tmp/a.jpg');
      n.setLocalPath('/tmp/a.jpg');
      expect(container.read(profileAvatarNotifierProvider).localPath,
          '/tmp/a.jpg');
    });

    test('setRemoteUrl and clearLocalPath compose', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      final ProfileAvatarNotifier n =
          container.read(profileAvatarNotifierProvider.notifier);
      n.setRemoteUrl('https://cdn/x.png');
      n.setLocalPath('/local');
      n.clearLocalPath();
      final ProfileAvatarData d = container.read(profileAvatarNotifierProvider);
      expect(d.localPath, isNull);
      expect(d.remoteUrl, 'https://cdn/x.png');
    });

    test('clearAll resets', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      final ProfileAvatarNotifier n =
          container.read(profileAvatarNotifierProvider.notifier);
      n.setRemoteUrl('u');
      n.setLocalPath('l');
      n.clearAll();
      expect(container.read(profileAvatarNotifierProvider),
          const ProfileAvatarData());
    });
  });
}
