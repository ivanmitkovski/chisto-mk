import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/profile/data/profile_avatar_state.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/feed_notification_bell.dart';
import 'package:chisto_mobile/shared/widgets/app_avatar.dart';
class FeedHeader extends StatelessWidget {
  const FeedHeader({
    super.key,
    required this.displayName,
    required this.unreadCount,
    required this.onProfileTap,
    required this.onNotificationTap,
  });

  /// Current user's display name (e.g. "John Doe"). Shown as "Hi, {first name}".
  final String displayName;
  final int unreadCount;
  final VoidCallback onProfileTap;
  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
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
              label: 'Open profile',
              child: GestureDetector(
                onTap: onProfileTap,
                behavior: HitTestBehavior.opaque,
                child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    width: 2,
                  ),
                ),
                child: AnimatedBuilder(
                  animation: profileAvatarState,
                  builder: (BuildContext context, Widget? child) {
                    return AppAvatar(
                      name: displayName,
                      size: 42,
                      fontSize: 14,
                      localImagePath: profileAvatarState.localPath,
                      imageUrl: profileAvatarState.remoteUrl,
                    );
                  },
                ),
              ),
            ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        'Hi, ',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w400,
                            ),
                      ),
                      Flexible(
                        child: Text(
                          _firstWord(displayName),
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Explore pollution sites near you',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          letterSpacing: -0.1,
                        ),
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

  static String _firstWord(String displayName) {
    final String trimmed = displayName.trim();
    if (trimmed.isEmpty) return 'there';
    final int space = trimmed.indexOf(' ');
    return space < 0 ? trimmed : trimmed.substring(0, space);
  }
}
