import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';

class ProfileUser {
  const ProfileUser({
    required this.id,
    required this.name,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.points,
    required this.totalPointsEarned,
    required this.level,
    required this.pointsToNextLevel,
    required this.avatarColor,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final int points;
  final int totalPointsEarned;
  final int level;
  final int pointsToNextLevel;
  final Color avatarColor;
  final String? avatarUrl;

  ProfileUser copyWith({
    String? name,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    int? points,
    int? totalPointsEarned,
    int? level,
    int? pointsToNextLevel,
    Color? avatarColor,
    String? avatarUrl,
  }) {
    return ProfileUser(
      id: id,
      name: name ?? this.name,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      points: points ?? this.points,
      totalPointsEarned: totalPointsEarned ?? this.totalPointsEarned,
      level: level ?? this.level,
      pointsToNextLevel: pointsToNextLevel ?? this.pointsToNextLevel,
      avatarColor: avatarColor ?? this.avatarColor,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

class WeeklyRankingEntry {
  const WeeklyRankingEntry({
    required this.position,
    required this.name,
    required this.points,
    this.isCurrentUser = false,
  });

  final int position;
  final String name;
  final int points;
  final bool isCurrentUser;
}

/// Temporary in-memory data for the profile experience until backend is wired.
class ProfileMockData {
  const ProfileMockData._();

  static const ProfileUser currentUser = ProfileUser(
    id: 'user-1',
    name: 'John Doe',
    firstName: 'John',
    lastName: 'Doe',
    phoneNumber: '+389 70 123 456',
    points: 1500,
    totalPointsEarned: 150,
    level: 2,
    pointsToNextLevel: 50,
    avatarColor: AppColors.primary,
    avatarUrl: null,
  );

  static const List<WeeklyRankingEntry> weeklyRankings = <WeeklyRankingEntry>[
    WeeklyRankingEntry(position: 1, name: 'Ruben Ekstrom Bothm', points: 1000),
    WeeklyRankingEntry(position: 2, name: 'Giana Gouse', points: 900),
    WeeklyRankingEntry(position: 3, name: 'Marley Bator', points: 800),
    WeeklyRankingEntry(position: 4, name: 'Brandon Calzoni', points: 750),
    WeeklyRankingEntry(position: 5, name: 'Carla Press', points: 700),
    WeeklyRankingEntry(position: 6, name: 'Makenna Septimus', points: 700),
    WeeklyRankingEntry(position: 7, name: 'Wilson Franci', points: 700),
    WeeklyRankingEntry(
      position: 8,
      name: 'John Doe',
      points: 700,
      isCurrentUser: true,
    ),
    WeeklyRankingEntry(position: 9, name: 'Tatiana Lubin', points: 680),
    WeeklyRankingEntry(position: 10, name: 'Gretchen Torff', points: 650),
  ];
}
