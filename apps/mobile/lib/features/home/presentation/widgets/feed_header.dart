import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/feed_notification_bell.dart';
class FeedHeader extends StatelessWidget {
  const FeedHeader({
    super.key,
    required this.unreadCount,
    required this.onProfileTap,
    required this.onNotificationTap,
  });

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
            GestureDetector(
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
                child: const CircleAvatar(
                  radius: 21,
                  backgroundImage:
                      AssetImage('assets/images/content/people_cleaning.png'),
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
                      Text(
                        'John',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
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
}
