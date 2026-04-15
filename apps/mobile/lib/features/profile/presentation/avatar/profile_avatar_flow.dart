import 'dart:io';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/features/profile/presentation/avatar/profile_avatar_crop_screen.dart';
import 'package:chisto_mobile/features/profile/presentation/avatar/profile_avatar_image_pipeline.dart';
import 'package:chisto_mobile/features/profile/presentation/avatar/profile_avatar_source_sheet.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

/// Result of [runProfileAvatarFlow]: cancel, clear avatar on server, or path to upload.
enum ProfileAvatarFlowKind { cancelled, remove, upload }

class ProfileAvatarFlowResult {
  const ProfileAvatarFlowResult._(this.kind, this.uploadPath);

  /// User dismissed the sheet or aborted pick/crop.
  static const ProfileAvatarFlowResult cancelled =
      ProfileAvatarFlowResult._(ProfileAvatarFlowKind.cancelled, null);

  /// User confirmed removing the profile photo (initials only).
  static const ProfileAvatarFlowResult remove =
      ProfileAvatarFlowResult._(ProfileAvatarFlowKind.remove, null);

  /// Compressed image ready for [ProfileRepository.uploadAvatar].
  static ProfileAvatarFlowResult upload(String path) =>
      ProfileAvatarFlowResult._(ProfileAvatarFlowKind.upload, path);

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
  if (!context.mounted || source == null) return ProfileAvatarFlowResult.cancelled;

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

  if (!context.mounted || picked == null) return ProfileAvatarFlowResult.cancelled;

  final XFile pickedFile = picked;
  final String? croppedPath = await Navigator.of(context, rootNavigator: true)
      .push<String>(_avatarCropPageRoute(pickedFile));

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
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.08),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.07),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                l10n.profileAvatarRemoveConfirmTitle,
                style: AppTypography.sectionHeader.copyWith(fontSize: 19),
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
              OutlinedButton(
                onPressed: () {
                  AppHaptics.tap();
                  Navigator.of(dialogContext).pop(false);
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  side: BorderSide(
                    color: AppColors.divider.withValues(alpha: 0.95),
                  ),
                  foregroundColor: AppColors.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                ),
                child: Text(
                  l10n.profileAvatarRemoveConfirmCancel,
                  style: AppTypography.buttonLabel.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 17,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 52,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    AppHaptics.warning();
                    Navigator.of(dialogContext).pop(true);
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: AppColors.accentDanger,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    ),
                  ),
                  child: Text(
                    l10n.profileAvatarRemoveConfirmRemove,
                    style: AppTypography.buttonLabel.copyWith(
                      color: AppColors.white,
                      fontSize: 17,
                    ),
                  ),
                ),
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
    barrierColor: Colors.black26,
    pageBuilder:
        (BuildContext context, Animation<double> a, Animation<double> b) {
      return ProfileAvatarCropScreen(picked: picked);
    },
    transitionDuration: AppMotion.medium,
    reverseTransitionDuration: AppMotion.fast,
    transitionsBuilder: (
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
