import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/core/validation/phone_display_formatter.dart';
import 'package:chisto_mobile/features/profile/domain/models/profile_user.dart';
import 'package:chisto_mobile/features/profile/presentation/providers/profile_avatar_notifier.dart';
import 'package:chisto_mobile/features/profile/presentation/screens/profile_general_info_screen.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_avatar.dart';
import 'package:chisto_mobile/shared/widgets/app_back_button.dart';
import 'package:chisto_mobile/shared/widgets/profile_avatar_peek_overlay.dart';

String? profilePeekNormalizeUrl(String? url) {
  final String? trimmed = url?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}

bool profileHeaderHasPeekablePhoto(ProfileUser user, ProfileAvatarData avatar) {
  if (avatar.localFile != null) return true;
  return profilePeekNormalizeUrl(avatar.remoteUrl ?? user.avatarUrl) != null;
}

ImageProvider? profileHeaderPeekImageProvider(
  ProfileUser user,
  ProfileAvatarData avatar,
) {
  final File? local = avatar.localFile;
  if (local != null) return FileImage(local);
  final String? url = profilePeekNormalizeUrl(avatar.remoteUrl ?? user.avatarUrl);
  if (url == null) return null;
  return NetworkImage(url);
}

/// Gradient profile header with avatar, name, and phone.
class ProfileHeader extends ConsumerWidget {
  const ProfileHeader({
    super.key,
    required this.user,
    this.onProfileUpdated,
  });

  final ProfileUser user;
  final void Function(ProfileUser)? onProfileUpdated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ProfileAvatarData avatar = ref.watch(profileAvatarNotifierProvider);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.primaryDark, AppColors.primary],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppSpacing.radiusCard),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Row(children: <Widget>[AppBackButton(), Spacer()]),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Builder(
                  builder: (BuildContext context) {
                    final bool canPeek = profileHeaderHasPeekablePhoto(user, avatar);
                    return GestureDetector(
                      onTap: () async {
                        AppHaptics.tap();
                        final ProfileUser? updated =
                            await Navigator.of(context).push<ProfileUser>(
                          MaterialPageRoute<ProfileUser>(
                            builder: (_) => ProfileGeneralInfoScreen(user: user),
                          ),
                        );
                        if (updated != null) {
                          onProfileUpdated?.call(updated);
                        }
                      },
                      onLongPress: canPeek
                          ? () {
                              final ImageProvider? img =
                                  profileHeaderPeekImageProvider(user, avatar);
                              if (img == null) return;
                              ProfileAvatarPeek.show(
                                context,
                                image: img,
                                semanticLabel:
                                    context.l10n.profileAvatarPeekSemantic,
                              );
                            }
                          : null,
                      onLongPressUp: canPeek ? ProfileAvatarPeek.hide : null,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: AppSpacing.avatarLg,
                        height: AppSpacing.avatarLg,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.white.withValues(alpha: 0.16),
                          border: Border.all(
                            color: AppColors.white.withValues(alpha: 0.7),
                            width: 2,
                          ),
                        ),
                        child: avatar.localFile != null
                            ? CircleAvatar(
                                backgroundColor: AppColors.white.withValues(
                                  alpha: 0.9,
                                ),
                                foregroundImage: FileImage(avatar.localFile!),
                              )
                            : AppAvatar(
                                name: user.name,
                                size: AppSpacing.avatarLg,
                                imageUrl: avatar.remoteUrl ?? user.avatarUrl,
                              ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.textTheme.titleMedium?.copyWith(
                          color: AppColors.textOnDark,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        formatPhoneForDisplay(user.phoneNumber),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textOnDarkMuted,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
