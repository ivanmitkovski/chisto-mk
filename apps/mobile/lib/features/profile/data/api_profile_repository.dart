import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/network/api_client.dart';
import 'package:chisto_mobile/features/profile/data/points_history_json.dart';
import 'package:chisto_mobile/features/profile/data/profile_me_json.dart';
import 'package:chisto_mobile/features/profile/data/weekly_rankings_json.dart';
import 'package:chisto_mobile/features/profile/domain/models/points_history_page.dart';
import 'package:chisto_mobile/features/profile/domain/models/profile_user.dart';
import 'package:chisto_mobile/features/profile/domain/models/weekly_rankings_result.dart';
import 'package:chisto_mobile/features/profile/domain/repositories/profile_repository.dart';

class ApiProfileRepository implements ProfileRepository {
  ApiProfileRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  @override
  Future<ProfileUser> getMe() async {
    final ApiResponse response = await _client.get('/auth/me');
    final Map<String, dynamic>? json = response.json;
    if (json == null) throw AppError.unknown();
    return profileUserFromMeJson(json);
  }

  @override
  Future<PointsHistoryPage> getPointsHistory({int limit = 30, String? cursor}) async {
    final StringBuffer path = StringBuffer('/auth/me/point-history?limit=$limit');
    final String? c = cursor?.trim();
    if (c != null && c.isNotEmpty) {
      path.write('&cursor=${Uri.encodeQueryComponent(c)}');
    }
    final ApiResponse response = await _client.get(path.toString());
    final Map<String, dynamic>? json = response.json;
    if (json == null) throw AppError.unknown();
    return pointsHistoryFromJson(json);
  }

  @override
  Future<WeeklyRankingsResult> getWeeklyRankings({int limit = 50}) async {
    final ApiResponse response = await _client.get(
      '/rankings/weekly?limit=$limit',
    );
    final Map<String, dynamic>? json = response.json;
    if (json == null) throw AppError.unknown();
    return weeklyRankingsFromJson(json);
  }

  @override
  Future<ProfileUser?> updateProfile({
    String? firstName,
    String? lastName,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{};
    if (firstName != null && firstName.trim().isNotEmpty) {
      body['firstName'] = firstName.trim();
    }
    if (lastName != null && lastName.trim().isNotEmpty) {
      body['lastName'] = lastName.trim();
    }
    if (body.isEmpty) return null;

    await _client.patch('/auth/me', body: body);
    return getMe();
  }

  @override
  Future<String> uploadAvatar(String filePath) async {
    final ApiResponse response = await _client.postMultipart(
      '/auth/me/avatar',
      <String>[filePath],
    );
    final String? avatarUrl = (response.json?['avatarUrl'] as String?)?.trim();
    if (avatarUrl == null || avatarUrl.isEmpty) {
      throw AppError.unknown();
    }
    return avatarUrl;
  }

  @override
  Future<void> removeAvatar() async {
    await _client.delete('/auth/me/avatar');
  }
}
