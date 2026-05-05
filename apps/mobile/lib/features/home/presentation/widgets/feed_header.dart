import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/feed_notification_bell.dart';
import 'package:chisto_mobile/features/profile/presentation/providers/profile_avatar_notifier.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/shared/widgets/app_avatar.dart';

class FeedHeader extends ConsumerWidget {
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

  /// Same greeting string as the header row (for layout / tests that need the line).
  static String greetingForChromeLayout(
    String displayName,
    AppLocalizations l10n,
  ) {
    return '${l10n.feedGreetingPrefix}${_firstWord(
      displayName,
      fallbackName: l10n.feedGreetingFallbackName,
    )}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ProfileAvatarData avatar = ref.watch(profileAvatarNotifierProvider);

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
                  child: AppAvatar(
                    name: displayName,
                    size: 42,
                    fontSize: 14,
                    localImagePath: avatar.localPath,
                    imageUrl: avatar.remoteUrl,
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
                        context.l10n.feedGreetingPrefix,
                        style: AppTypography.cardTitle.copyWith(
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          _firstWord(
                            displayName,
                            fallbackName: context.l10n.feedGreetingFallbackName,
                          ),
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.cardTitle.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    context.l10n.feedHeaderSubtitle,
                    style: AppTypography.cardSubtitle.copyWith(
                      color: AppColors.textMuted,
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

String _firstWord(String displayName, {required String fallbackName}) {
  final String trimmed = displayName.trim();
  if (trimmed.isEmpty) return fallbackName;
  final int space = trimmed.indexOf(' ');
  return space < 0 ? trimmed : trimmed.substring(0, space);
}
