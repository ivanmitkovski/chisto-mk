import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_avatar.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_home/src/presentation/widgets/feed_notification_bell.dart';
import 'package:feature_notifications/feature_notifications.dart';
import 'package:feature_profile/feature_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FeedHeader extends ConsumerWidget {
  const FeedHeader({
    super.key,
    required this.displayName,
    required this.onProfileTap,
    required this.onNotificationTap,
    this.profileAvatarKey,
  });

  /// Current user's display name (e.g. "John Doe"). Shown as "Hi, {first name}".
  final String displayName;
  final VoidCallback onProfileTap;
  final VoidCallback onNotificationTap;

  /// Optional [GlobalKey] on the profile avatar (home coach overlay).
  final GlobalKey? profileAvatarKey;

  /// Same greeting string as the header row (for layout / tests that need the line).
  static String greetingForChromeLayout(
    String displayName,
    AppLocalizations l10n,
  ) {
    return '${l10n.feedGreetingPrefix}${_firstWord(displayName, fallbackName: l10n.feedGreetingFallbackName)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final int unreadCount = ref.watch(notificationsUnreadCountProvider);
    final ProfileAvatarData avatar = ref.watch(profileAvatarNotifierProvider);

    Widget profileHit = GestureDetector(
      onTap: onProfileTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 46,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.25),
            width: 2,
          ),
        ),
        child: AppAvatar(
          name: displayName,
          size: 42,
          fontSize: 14,
          localImagePath: avatar.localPath,
          imageUrl: avatar.remoteUrl,
        ),
      ),
    );
    if (profileAvatarKey != null) {
      profileHit = KeyedSubtree(key: profileAvatarKey, child: profileHit);
    }

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg - AppSpacing.xxs,
          AppSpacing.md,
        ),
        child: Row(
          children: <Widget>[
            Semantics(
              button: true,
              label: context.l10n.feedOpenProfileSemantics,
              child: profileHit,
            ),
            const SizedBox(width: AppSpacing.feedHeaderAvatarToTextGap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        context.l10n.feedGreetingPrefix,
                        style: AppTypography.cardTitle(
                          textTheme,
                        ).copyWith(fontWeight: FontWeight.w400),
                      ),
                      Flexible(
                        child: Text(
                          _firstWord(
                            displayName,
                            fallbackName: context.l10n.feedGreetingFallbackName,
                          ),
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.cardTitle(
                            textTheme,
                          ).copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    context.l10n.feedHeaderSubtitle,
                    style: AppTypography.cardSubtitle(
                      textTheme,
                    ).copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            FeedNotificationBell(
              unreadCount: unreadCount,
              onTap: onNotificationTap,
            ),
          ],
        ),
      ),
    );
  }
}

String _firstWord(String displayName, {required String fallbackName}) {
  final String trimmed = displayName.trim();
  if (trimmed.isEmpty) return fallbackName;
  final int space = trimmed.indexOf(' ');
  return space < 0 ? trimmed : trimmed.substring(0, space);
}
