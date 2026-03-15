import 'package:chisto_mobile/features/profile/data/profile_mock_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProfileMockData', () {
    test('currentUser is non-empty and has expected structure', () {
      const ProfileUser user = ProfileMockData.currentUser;

      expect(user.id, isNotEmpty);
      expect(user.name, isNotEmpty);
      expect(user.phoneNumber, isNotEmpty);
      expect(user.points, greaterThanOrEqualTo(0));
      expect(user.level, greaterThanOrEqualTo(0));
      expect(user.pointsToNextLevel, greaterThanOrEqualTo(0));
      expect(user.avatarColor, isNotNull);
    });

    test('currentUser has expected values', () {
      const ProfileUser user = ProfileMockData.currentUser;

      expect(user.id, 'user-1');
      expect(user.name, 'John Doe');
      expect(user.phoneNumber, '+389 70 123 456');
      expect(user.points, 1500);
      expect(user.level, 2);
      expect(user.pointsToNextLevel, 50);
    });

    test('weeklyRankings is non-empty', () {
      expect(ProfileMockData.weeklyRankings, isNotEmpty);
    });

    test('weeklyRankings has expected structure for each entry', () {
      for (final WeeklyRankingEntry entry in ProfileMockData.weeklyRankings) {
        expect(entry.position, greaterThan(0));
        expect(entry.name, isNotEmpty);
        expect(entry.points, greaterThanOrEqualTo(0));
      }
    });

    test('weeklyRankings positions are sequential', () {
      final List<int> positions = ProfileMockData.weeklyRankings
          .map((WeeklyRankingEntry e) => e.position)
          .toList();

      for (int i = 0; i < positions.length; i++) {
        expect(positions[i], i + 1);
      }
    });

    test('weeklyRankings has exactly one current user', () {
      final int currentUserCount = ProfileMockData.weeklyRankings
          .where((WeeklyRankingEntry e) => e.isCurrentUser)
          .length;

      expect(currentUserCount, 1);
    });

    test('current user in rankings matches currentUser name', () {
      final WeeklyRankingEntry? current = ProfileMockData.weeklyRankings
          .where((WeeklyRankingEntry e) => e.isCurrentUser)
          .firstOrNull;

      expect(current, isNotNull);
      expect(current!.name, ProfileMockData.currentUser.name);
    });
  });
}
