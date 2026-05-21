import 'package:chisto_mobile/features/notifications/domain/models/user_notification.dart';
import 'package:chisto_mobile/features/notifications/domain/notification_preference_groups.dart';
import 'package:chisto_mobile/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('kNotificationPreferenceGroups covers every UserNotificationType once', () {
    final Set<UserNotificationType> covered = <UserNotificationType>{};
    for (final NotificationPreferenceGroup group in kNotificationPreferenceGroups) {
      for (final UserNotificationType type in group.types) {
        expect(
          covered.add(type),
          isTrue,
          reason: 'duplicate type $type in preference groups',
        );
      }
    }
    expect(covered, UserNotificationType.values.toSet());
    expect(kNotificationPreferenceGroups, hasLength(8));
  });

  test('isNotificationPreferenceGroupEnabled is true when any type is unmuted', () {
    final Map<UserNotificationType, NotificationPreference> byType =
        <UserNotificationType, NotificationPreference>{
      UserNotificationType.system: const NotificationPreference(
        type: UserNotificationType.system,
        muted: true,
      ),
      UserNotificationType.achievement: const NotificationPreference(
        type: UserNotificationType.achievement,
        muted: false,
      ),
      UserNotificationType.welcome: const NotificationPreference(
        type: UserNotificationType.welcome,
        muted: true,
      ),
    };
    const NotificationPreferenceGroup system = NotificationPreferenceGroup(
      id: NotificationPreferenceGroupId.system,
      types: <UserNotificationType>[
        UserNotificationType.system,
        UserNotificationType.achievement,
        UserNotificationType.welcome,
      ],
    );
    expect(
      isNotificationPreferenceGroupEnabled(system, byType),
      isTrue,
    );
  });

  test('applyGroupMuteToMap updates every type in the group', () {
    const NotificationPreferenceGroup system = NotificationPreferenceGroup(
      id: NotificationPreferenceGroupId.system,
      types: <UserNotificationType>[
        UserNotificationType.system,
        UserNotificationType.achievement,
        UserNotificationType.welcome,
      ],
    );
    final Map<UserNotificationType, NotificationPreference> next =
        applyGroupMuteToMap(
      <UserNotificationType, NotificationPreference>{},
      system,
      muted: true,
      mutedUntil: DateTime.utc(2026, 5, 20, 12),
    );
    for (final UserNotificationType type in system.types) {
      final NotificationPreference pref = next[type]!;
      expect(pref.muted, isTrue);
      expect(pref.mutedUntil, DateTime.utc(2026, 5, 20, 12));
    }
  });

  test('group titles are unique across catalog rows', () {
    final AppLocalizationsEn l10n = AppLocalizationsEn();
    final Set<String> titles = <String>{};
    for (final NotificationPreferenceGroup group in kNotificationPreferenceGroups) {
      final String title = notificationPreferenceGroupTitle(l10n, group.id);
      expect(
        titles.add(title),
        isTrue,
        reason: 'duplicate title "$title" for ${group.id}',
      );
    }
  });
}
