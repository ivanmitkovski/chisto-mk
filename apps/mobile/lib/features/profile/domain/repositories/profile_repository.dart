import 'package:chisto_mobile/features/profile/domain/models/points_history_page.dart';
import 'package:chisto_mobile/features/profile/domain/models/profile_user.dart';
import 'package:chisto_mobile/features/profile/domain/models/weekly_rankings_result.dart';

abstract class ProfileRepository {
  Future<ProfileUser> getMe();

  /// Paginated point awards (newest first). [cursor] is from the previous page's [PointsHistoryPage.nextCursor].
  Future<PointsHistoryPage> getPointsHistory({int limit = 30, String? cursor});

  /// Updates profile and returns the updated user, or null if no changes were sent.
  Future<ProfileUser?> updateProfile({String? firstName, String? lastName});

  Future<String> uploadAvatar(String filePath);

  Future<void> removeAvatar();

  Future<WeeklyRankingsResult> getWeeklyRankings({int limit = 50});
}
