import 'package:flutter/material.dart';

/// Authenticated citizen profile from `GET /auth/me` (plus derived display fields).
class ProfileUser {
  const ProfileUser({
    required this.id,
    required this.name,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.points,
    required this.totalPointsEarned,
    required this.level,
    required this.levelTierKey,
    required this.levelDisplayName,
    required this.pointsToNextLevel,
    required this.levelProgress,
    required this.pointsInLevel,
    required this.weeklyPoints,
    required this.weeklyRank,
    required this.weekStartsAt,
    required this.weekEndsAt,
    required this.avatarColor,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;

  /// Spendable points balance (`pointsBalance` from API).
  final int points;

  /// Lifetime XP (`totalPointsEarned`); level curve is server-defined from this.
  final int totalPointsEarned;

  final int level;
  final String levelTierKey;
  final String levelDisplayName;
  final int pointsToNextLevel;
  final double levelProgress;
  final int pointsInLevel;

  final int weeklyPoints;
  final int? weeklyRank;
  final String weekStartsAt;
  final String weekEndsAt;

  final Color avatarColor;
  final String? avatarUrl;

  ProfileUser copyWith({
    String? name,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    int? points,
    int? totalPointsEarned,
    int? level,
    String? levelTierKey,
    String? levelDisplayName,
    int? pointsToNextLevel,
    double? levelProgress,
    int? pointsInLevel,
    int? weeklyPoints,
    int? weeklyRank,
    String? weekStartsAt,
    String? weekEndsAt,
    Color? avatarColor,
    String? avatarUrl,
  }) {
    return ProfileUser(
      id: id,
      name: name ?? this.name,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      points: points ?? this.points,
      totalPointsEarned: totalPointsEarned ?? this.totalPointsEarned,
      level: level ?? this.level,
      levelTierKey: levelTierKey ?? this.levelTierKey,
      levelDisplayName: levelDisplayName ?? this.levelDisplayName,
      pointsToNextLevel: pointsToNextLevel ?? this.pointsToNextLevel,
      levelProgress: levelProgress ?? this.levelProgress,
      pointsInLevel: pointsInLevel ?? this.pointsInLevel,
      weeklyPoints: weeklyPoints ?? this.weeklyPoints,
      weeklyRank: weeklyRank ?? this.weeklyRank,
      weekStartsAt: weekStartsAt ?? this.weekStartsAt,
      weekEndsAt: weekEndsAt ?? this.weekEndsAt,
      avatarColor: avatarColor ?? this.avatarColor,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
