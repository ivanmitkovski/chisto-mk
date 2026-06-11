import 'package:feature_profile/src/domain/models/points_history_page.dart';
import 'package:feature_profile/src/domain/models/profile_user.dart';
import 'package:feature_profile/src/domain/models/weekly_rankings_result.dart';

abstract class ProfileRepository {
  Future<ProfileUser> getMe();

  /// Paginated point awards (newest first). [cursor] is from the previous page's [PointsHistoryPage.nextCursor].
  Future<PointsHistoryPage> getPointsHistory({int limit = 30, String? cursor});

  /// Updates profile and returns the updated user, or null if no changes were sent.
  Future<ProfileUser?> updateProfile({
    String? firstName,
    String? lastName,
    String? locale,
  });

  Future<String> uploadAvatar(String filePath);

  Future<void> removeAvatar();

  /// Persists notification locale (`en`, `mk`, or `sq`) on the server profile.
  Future<void> updateLocale(String locale);

  Future<WeeklyRankingsResult> getWeeklyRankings({int limit = 50});
}
