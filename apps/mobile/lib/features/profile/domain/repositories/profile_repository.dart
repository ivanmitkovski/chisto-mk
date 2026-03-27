import 'package:chisto_mobile/features/profile/data/profile_mock_data.dart';

abstract class ProfileRepository {
  Future<ProfileUser> getMe();

  /// Updates profile and returns the updated user, or null if no changes were sent.
  Future<ProfileUser?> updateProfile({String? firstName, String? lastName});

  Future<String?> uploadAvatar(String filePath);

  Future<void> removeAvatar();
}
