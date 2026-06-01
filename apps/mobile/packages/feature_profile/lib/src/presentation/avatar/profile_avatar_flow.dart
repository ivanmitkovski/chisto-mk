import 'dart:io';

import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_snack.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_profile/src/presentation/avatar/profile_avatar_crop_screen.dart';
import 'package:feature_profile/src/presentation/avatar/profile_avatar_image_pipeline.dart';
import 'package:feature_profile/src/presentation/avatar/profile_avatar_source_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

/// Result of [runProfileAvatarFlow]: cancel, clear avatar on server, or path to upload.
enum ProfileAvatarFlowKind { cancelled, remove, upload }

class ProfileAvatarFlowResult {
  const ProfileAvatarFlowResult._(this.kind, this.uploadPath);

  /// Compressed image ready for [ProfileRepository.uploadAvatar].
  factory ProfileAvatarFlowResult.upload(String path) =>
      ProfileAvatarFlowResult._(ProfileAvatarFlowKind.upload, path);

  /// User dismissed the sheet or aborted pick/crop.
  static const ProfileAvatarFlowResult cancelled = ProfileAvatarFlowResult._(
    ProfileAvatarFlowKind.cancelled,
    null,
  );

  /// User confirmed removing the profile photo (initials only).
  static const ProfileAvatarFlowResult remove = ProfileAvatarFlowResult._(
    ProfileAvatarFlowKind.remove,
    null,
  );

  final ProfileAvatarFlowKind kind;
  final String? uploadPath;
}

/// Source sheet → pick → crop route (prep inside card) → compress; or remove after confirm.
///
/// Selfie uses native [ImagePicker] camera (not the `camera` plugin).
Future<ProfileAvatarFlowResult> runProfileAvatarFlow(
  BuildContext context, {
  bool showRemoveOption = false,
}) async {
  final ProfileAvatarSource? source = await showProfileAvatarSourceSheet(
    context,
    showRemoveOption: showRemoveOption,
  );
  if (!context.mounted || source == null) {
    return ProfileAvatarFlowResult.cancelled;
  }

  if (source == ProfileAvatarSource.remove) {
    final bool ok = await _confirmRemoveAvatar(context);
    if (!context.mounted || !ok) return ProfileAvatarFlowResult.cancelled;
    return ProfileAvatarFlowResult.remove;
  }

  XFile? picked;
  if (source == ProfileAvatarSource.selfie) {
    try {
      final ImagePicker picker = ImagePicker();
      picked = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 88,
        maxWidth: 3072,
        maxHeight: 3072,
      );
    } on PlatformException {
      if (context.mounted) {
        AppSnack.show(
          context,
          message: context.l10n.profileAvatarCameraUnavailable,
          type: AppSnackType.warning,
        );
      }
      return ProfileAvatarFlowResult.cancelled;
    }
  } else if (source == ProfileAvatarSource.gallery) {
    final ImagePicker picker = ImagePicker();
    picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 2048,
      maxHeight: 2048,
    );
  }

  if (!context.mounted || picked == null) {
    return ProfileAvatarFlowResult.cancelled;
  }

  final XFile pickedFile = picked;
  final String? croppedPath = await Navigator.of(
    context,
    rootNavigator: true,
  ).push<String>(_avatarCropPageRoute(pickedFile));

  if (!context.mounted || croppedPath == null || croppedPath.isEmpty) {
    return ProfileAvatarFlowResult.cancelled;
  }

  final File cropped = File(croppedPath);
  if (!cropped.existsSync()) return ProfileAvatarFlowResult.cancelled;

  try {
    final File? compressed = await compressForAvatarUpload(cropped);
    final String path = compressed?.path ?? cropped.path;
    return ProfileAvatarFlowResult.upload(path);
  } catch (_) {
    if (context.mounted) {
      AppSnack.show(
        context,
        message: context.l10n.profileAvatarProcessPhotoFailed,
        type: AppSnackType.warning,
      );
    }
    return ProfileAvatarFlowResult.cancelled;
  }
}

Future<bool> _confirmRemoveAvatar(BuildContext context) async {
  final l10n = context.l10n;
  final bool? ok = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierColor: AppColors.overlay,
    builder: (BuildContext dialogContext) {
      final TextTheme textTheme = Theme.of(dialogContext).textTheme;
      return Dialog(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: AppColors.panelBackground,
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            border: Border.all(
              color: AppColors.divider.withValues(alpha: 0.75),
            ),
            boxShadow: AppShadows.profileAvatarCard(),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                l10n.profileAvatarRemoveConfirmTitle,
                style: AppTypography.sectionHeader(textTheme),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.profileAvatarRemoveConfirmMessage,
                style: AppTypography.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton.outlined(
                label: l10n.profileAvatarRemoveConfirmCancel,
                onPressed: () {
                  Navigator.of(dialogContext).pop(false);
                },
                expand: true,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton.destructive(
                label: l10n.profileAvatarRemoveConfirmRemove,
                onPressed: () {
                  Navigator.of(dialogContext).pop(true);
                },
                expand: true,
              ),
            ],
          ),
        ),
      );
    },
  );
  return ok ?? false;
}

PageRoute<String> _avatarCropPageRoute(XFile picked) {
  return PageRouteBuilder<String>(
    fullscreenDialog: true,
    opaque: true,
    barrierColor: AppColors.overlayLight,
    pageBuilder:
        (BuildContext context, Animation<double> a, Animation<double> b) {
          return ProfileAvatarCropScreen(picked: picked);
        },
    transitionDuration: AppMotion.medium,
    reverseTransitionDuration: AppMotion.fast,
    transitionsBuilder:
        (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondary,
          Widget child,
        ) {
          final Animation<double> curved = CurvedAnimation(
            parent: animation,
            curve: AppMotion.smooth,
            reverseCurve: AppMotion.sharpDecelerate.flipped,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.03),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
  );
}
