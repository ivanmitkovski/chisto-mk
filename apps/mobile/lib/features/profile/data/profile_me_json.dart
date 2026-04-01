import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/features/profile/domain/models/profile_user.dart';

/// Parses `GET /auth/me` JSON into [ProfileUser] (shared with tests).
ProfileUser profileUserFromMeJson(Map<String, dynamic> json) {
  final String id = json['id'] as String? ?? '';
  final String firstName = (json['firstName'] as String?)?.trim() ?? '';
  final String lastName = (json['lastName'] as String?)?.trim() ?? '';
  final String name = '$firstName $lastName'.trim();
  final String email = (json['email'] as String?)?.trim() ?? '';
  final String phoneNumber =
      (json['phoneNumber'] as String?)?.trim().isNotEmpty == true
      ? (json['phoneNumber'] as String)
      : '—';
  final int pointsBalance = (json['pointsBalance'] as num?)?.toInt() ?? 0;
  final int totalPointsEarned =
      (json['totalPointsEarned'] as num?)?.toInt() ?? 0;
  final String? avatarUrl = (json['avatarUrl'] as String?)?.trim();

  final int level = (json['level'] as num?)?.toInt() ?? 1;
  final String levelTierKey =
      (json['levelTierKey'] as String?)?.trim().isNotEmpty == true
      ? (json['levelTierKey'] as String).trim()
      : 'numeric_${level.clamp(1, 999)}';
  final String levelDisplayName =
      (json['levelDisplayName'] as String?)?.trim().isNotEmpty == true
      ? (json['levelDisplayName'] as String).trim()
      : 'Level $level';
  final double levelProgress =
      (json['levelProgress'] as num?)?.toDouble() ?? 0.0;
  final int pointsInLevel = (json['pointsInLevel'] as num?)?.toInt() ?? 0;
  final int pointsToNextLevel =
      (json['pointsToNextLevel'] as num?)?.toInt() ?? 1;

  final int weeklyPoints = (json['weeklyPoints'] as num?)?.toInt() ?? 0;
  final int? weeklyRank = (json['weeklyRank'] as num?)?.toInt();
  final String weekStartsAt = json['weekStartsAt'] as String? ?? '';
  final String weekEndsAt = json['weekEndsAt'] as String? ?? '';

  return ProfileUser(
    id: id,
    name: name.isEmpty ? 'User' : name,
    firstName: firstName,
    lastName: lastName,
    email: email,
    phoneNumber: phoneNumber,
    points: pointsBalance,
    totalPointsEarned: totalPointsEarned,
    level: level,
    levelTierKey: levelTierKey,
    levelDisplayName: levelDisplayName,
    pointsToNextLevel: pointsToNextLevel,
    levelProgress: levelProgress.clamp(0.0, 1.0),
    pointsInLevel: pointsInLevel,
    weeklyPoints: weeklyPoints,
    weeklyRank: weeklyRank,
    weekStartsAt: weekStartsAt,
    weekEndsAt: weekEndsAt,
    avatarColor: AppColors.primary,
    avatarUrl: (avatarUrl?.isNotEmpty ?? false) ? avatarUrl : null,
  );
}
