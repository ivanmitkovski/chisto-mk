import 'package:chisto_mobile/features/profile/domain/models/points_history_page.dart';
import 'package:chisto_mobile/features/profile/domain/models/profile_user.dart';
import 'package:chisto_mobile/features/profile/domain/models/weekly_rankings_result.dart';
import 'package:chisto_mobile/features/profile/domain/repositories/profile_repository.dart';

/// Test-only configurable [ProfileRepository].
class TestingProfileRepository implements ProfileRepository {
  TestingProfileRepository({
    required Future<ProfileUser> Function() getMeImpl,
    Future<PointsHistoryPage> Function({int limit, String? cursor})?
        getPointsHistoryImpl,
    Future<WeeklyRankingsResult> Function({int limit})? getWeeklyRankingsImpl,
  })  : _getMeImpl = getMeImpl,
        _getPointsHistoryImpl = getPointsHistoryImpl,
        _getWeeklyRankingsImpl = getWeeklyRankingsImpl;

  final Future<ProfileUser> Function() _getMeImpl;
  final Future<PointsHistoryPage> Function({int limit, String? cursor})?
      _getPointsHistoryImpl;
  final Future<WeeklyRankingsResult> Function({int limit})?
      _getWeeklyRankingsImpl;

  @override
  Future<ProfileUser> getMe() => _getMeImpl();

  @override
  Future<PointsHistoryPage> getPointsHistory({
    int limit = 30,
    String? cursor,
  }) {
    final Future<PointsHistoryPage> Function({int limit, String? cursor})? f =
        _getPointsHistoryImpl;
    if (f == null) {
      throw StateError('getPointsHistory not stubbed');
    }
    return f(limit: limit, cursor: cursor);
  }

  @override
  Future<ProfileUser?> updateProfile({String? firstName, String? lastName}) {
    throw UnimplementedError();
  }

  @override
  Future<String> uploadAvatar(String filePath) {
    throw UnimplementedError();
  }

  @override
  Future<void> removeAvatar() {
    throw UnimplementedError();
  }

  @override
  Future<WeeklyRankingsResult> getWeeklyRankings({int limit = 50}) {
    final Future<WeeklyRankingsResult> Function({int limit})? f =
        _getWeeklyRankingsImpl;
    if (f == null) {
      throw StateError('getWeeklyRankings not stubbed');
    }
    return f(limit: limit);
  }
}
