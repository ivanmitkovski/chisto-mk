import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/network/api_client.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/features/profile/data/profile_mock_data.dart';
import 'package:chisto_mobile/features/profile/domain/repositories/profile_repository.dart';

class ApiProfileRepository implements ProfileRepository {
  ApiProfileRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  @override
  Future<ProfileUser> getMe() async {
    final ApiResponse response = await _client.get('/auth/me');
    final Map<String, dynamic>? json = response.json;
    if (json == null) throw AppError.unknown();

    final String id = json['id'] as String? ?? '';
    final String firstName = (json['firstName'] as String?)?.trim() ?? '';
    final String lastName = (json['lastName'] as String?)?.trim() ?? '';
    final String name = '$firstName $lastName'.trim();
    final String phoneNumber =
        (json['phoneNumber'] as String?)?.trim().isNotEmpty == true
            ? (json['phoneNumber'] as String)
            : '—';
    final int pointsBalance = (json['pointsBalance'] as num?)?.toInt() ?? 0;
    final int totalPointsEarned =
        (json['totalPointsEarned'] as num?)?.toInt() ?? 0;

    final int level = (totalPointsEarned ~/ 100) + 1;
    final int pointsToNextLevel = 100 - (totalPointsEarned % 100);

    return ProfileUser(
      id: id,
      name: name.isEmpty ? 'User' : name,
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
      points: pointsBalance,
      totalPointsEarned: totalPointsEarned,
      level: level,
      pointsToNextLevel: pointsToNextLevel,
      avatarColor: AppColors.primary,
    );
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

    await _client.patch(
      '/auth/me',
      body: body,
    );
    return getMe();
  }
}
