import 'dart:io';

import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/shared/widgets/app_avatar.dart';
import 'package:chisto_mobile/shared/widgets/profile_avatar_peek_overlay.dart';

/// Avatar stack, camera badge, and caption for profile general info.
class ProfileAvatarSection extends StatelessWidget {
  const ProfileAvatarSection({
    super.key,
    required this.avatarDisplayName,
    required this.localAvatarPath,
    required this.remoteAvatarUrl,
    required this.isSaving,
    required this.isAvatarBusy,
    required this.canPeekAvatar,
    required this.peekImageProvider,
    required this.onChangeAvatar,
  });

  final String avatarDisplayName;
  final String? localAvatarPath;
  final String? remoteAvatarUrl;
  final bool isSaving;
  final bool isAvatarBusy;
  final bool canPeekAvatar;
  final ImageProvider? Function() peekImageProvider;
  final VoidCallback onChangeAvatar;

  @override
  Widget build(BuildContext context) {
    final double avatarDiameter = AppSpacing.avatarLg + AppSpacing.lg;
    return Center(
      child: Column(
        children: <Widget>[
          Semantics(
            label: isAvatarBusy
                ? context.l10n.profileGeneralAvatarSemanticUpdating
                : context.l10n.profileGeneralAvatarSemanticChange,
            button: true,
            enabled: !isSaving && !isAvatarBusy,
            child: Material(
              color: AppColors.transparent,
              child: InkWell(
                onTap: isSaving || isAvatarBusy ? null : onChangeAvatar,
                onLongPress: canPeekAvatar
                    ? () {
                        final ImageProvider? image = peekImageProvider();
                        if (image == null) return;
                        ProfileAvatarPeek.show(
                          context,
                          image: image,
                          semanticLabel:
                              context.l10n.profileAvatarPeekSemantic,
                        );
                      }
                    : null,
                onLongPressUp:
                    canPeekAvatar ? ProfileAvatarPeek.hide : null,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: avatarDiameter + 14,
                  height: avatarDiameter + 14,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      ClipOval(
                        clipBehavior: Clip.antiAlias,
                        child: AnimatedContainer(
                          duration: AppMotion.fast,
                          curve: AppMotion.smooth,
                          width: avatarDiameter,
                          height: avatarDiameter,
                          decoration: BoxDecoration(
                            color: AppColors.inputFill,
                            border: Border.all(
                              color: isAvatarBusy
                                  ? AppColors.primary
                                      .withValues(alpha: 0.45)
                                  : AppColors.primaryDark
                                      .withValues(alpha: 0.12),
                              width: isAvatarBusy ? 2.5 : 1.5,
                            ),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            clipBehavior: Clip.hardEdge,
                            children: <Widget>[
                              Positioned.fill(
                                child: localAvatarPath != null
                                    ? Image.file(
                                        File(localAvatarPath!),
                                        fit: BoxFit.cover,
                                        filterQuality: FilterQuality.medium,
                                      )
                                    : AppAvatar(
                                        name: avatarDisplayName,
                                        size: avatarDiameter,
                                        imageUrl: remoteAvatarUrl,
                                      ),
                              ),
                              if (isAvatarBusy)
                                Positioned.fill(
                                  child: ColoredBox(
                                    color: AppColors.black
                                        .withValues(alpha: 0.28),
                                    child: const Center(
                                      child: SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: AppColors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (!isAvatarBusy)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryDark,
                              border: Border.all(
                                color: AppColors.white,
                                width: 2,
                              ),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: AppColors.black
                                      .withValues(alpha: 0.12),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(
                                Icons.camera_alt_rounded,
                                size: 16,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ExcludeSemantics(
            child: AnimatedSwitcher(
              duration: AppMotion.fast,
              switchInCurve: AppMotion.smooth,
              switchOutCurve: AppMotion.standardCurve,
              child: Text(
                isAvatarBusy
                    ? context.l10n.profileAvatarUploadingCaption
                    : context.l10n.profileAvatarTapToChange,
                key: ValueKey<bool>(isAvatarBusy),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.1,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
