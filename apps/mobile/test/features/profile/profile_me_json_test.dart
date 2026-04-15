import 'package:chisto_mobile/features/profile/data/profile_me_json.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('profileUserFromMeJson', () {
    test('parses extended me payload including gamification and weekly fields', () {
      final user = profileUserFromMeJson(<String, dynamic>{
        'id': 'u1',
        'firstName': ' Ana ',
        'lastName': ' B ',
        'email': 'ana@example.com',
        'phoneNumber': '+38970111222',
        'pointsBalance': 40,
        'totalPointsEarned': 123,
        'level': 3,
        'levelTierKey': 'numeric_3',
        'levelDisplayName': 'Level 3',
        'levelProgress': 0.42,
        'pointsInLevel': 10,
        'pointsToNextLevel': 14,
        'weeklyPoints': 37,
        'weeklyRank': 2,
        'weekStartsAt': '2026-03-30T22:00:00.000Z',
        'weekEndsAt': '2026-04-05T21:59:59.999Z',
        'avatarUrl': ' https://x/y ',
      });

      expect(user.id, 'u1');
      expect(user.name, 'Ana B');
      expect(user.email, 'ana@example.com');
      expect(user.points, 40);
      expect(user.totalPointsEarned, 123);
      expect(user.level, 3);
      expect(user.levelTierKey, 'numeric_3');
      expect(user.levelDisplayName, 'Level 3');
      expect(user.levelProgress, 0.42);
      expect(user.pointsInLevel, 10);
      expect(user.pointsToNextLevel, 14);
      expect(user.weeklyPoints, 37);
      expect(user.weeklyRank, 2);
      expect(user.weekStartsAt, isNotEmpty);
      expect(user.avatarUrl, 'https://x/y');
    });

    test('synthesizes tier key from level when API omits tier fields', () {
      final user = profileUserFromMeJson(<String, dynamic>{
        'id': 'u1',
        'firstName': 'A',
        'lastName': 'B',
        'email': 'a@b.c',
        'phoneNumber': '+1',
        'pointsBalance': 0,
        'totalPointsEarned': 0,
        'level': 7,
        'levelProgress': 0,
        'pointsInLevel': 0,
        'pointsToNextLevel': 10,
        'weeklyPoints': 0,
        'weeklyRank': null,
        'weekStartsAt': '',
        'weekEndsAt': '',
      });
      expect(user.levelTierKey, 'numeric_7');
      expect(user.levelDisplayName, 'Level 7');
    });

    test('treats null weeklyRank as absent rank', () {
      final user = profileUserFromMeJson(<String, dynamic>{
        'id': 'u1',
        'firstName': 'A',
        'lastName': 'B',
        'email': 'a@b.c',
        'phoneNumber': '+1',
        'pointsBalance': 0,
        'totalPointsEarned': 0,
        'level': 1,
        'levelTierKey': 'numeric_1',
        'levelDisplayName': 'Level 1',
        'levelProgress': 0,
        'pointsInLevel': 0,
        'pointsToNextLevel': 25,
        'weeklyPoints': 0,
        'weeklyRank': null,
        'weekStartsAt': '',
        'weekEndsAt': '',
      });
      expect(user.weeklyRank, isNull);
    });
  });
}
