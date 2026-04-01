import 'dart:io';
import 'dart:typed_data';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/profile/presentation/avatar/profile_avatar_image_pipeline.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Circular avatar crop: 1:1 viewport with circle mask; user pans and pinches.
/// Prep (copy, settle, decode) runs after the route is shown; loading UI is
/// only inside the crop card.
Widget _avatarCropGridOverlay(BuildContext context, Rect rect) {
  return ClipOval(
    child: SizedBox(
      width: rect.width,
      height: rect.height,
      child: CustomPaint(
        painter: _AvatarCropGridPainter(
          lineColor: AppColors.white.withValues(alpha: 0.28),
        ),
      ),
    ),
  );
}

/// Rule-of-thirds guides inside the crop area (camera-style framing).
class _AvatarCropGridPainter extends CustomPainter {
  _AvatarCropGridPainter({required this.lineColor});

  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final double w = size.width;
    final double h = size.height;
    canvas.drawLine(Offset(w / 3, 0), Offset(w / 3, h), paint);
    canvas.drawLine(Offset(2 * w / 3, 0), Offset(2 * w / 3, h), paint);
    canvas.drawLine(Offset(0, h / 3), Offset(w, h / 3), paint);
    canvas.drawLine(Offset(0, 2 * h / 3), Offset(w, 2 * h / 3), paint);
  }

  @override
  bool shouldRepaint(covariant _AvatarCropGridPainter oldDelegate) =>
      oldDelegate.lineColor != lineColor;
}

class ProfileAvatarCropScreen extends StatefulWidget {
  const ProfileAvatarCropScreen({super.key, required this.picked});

  final XFile picked;

  @override
  State<ProfileAvatarCropScreen> createState() =>
      _ProfileAvatarCropScreenState();
}

class _ProfileAvatarCropScreenState extends State<ProfileAvatarCropScreen> {
  final CropController _controller = CropController();
  Uint8List? _imageBytes;
  bool _preparing = true;
  bool _cropping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepareImage());
  }

  Future<void> _prepareImage() async {
    if (!mounted) return;
    final MediaQueryData mq = MediaQuery.of(context);
    // Enough resolution for pinch-zoom in the crop card without decoding
    // full 12MP+ originals.
    final int maxDecodeWidth =
        (mq.size.shortestSide * mq.devicePixelRatio * 2.2)
            .round()
            .clamp(1024, kAvatarCropDecodeWidthMax);

    try {
      await waitAfterProfileAvatarPicker();
      if (!mounted) return;

      final String pathForCrop = await materializePickForNativeCrop(
        widget.picked,
      );
      if (!File(pathForCrop).existsSync()) {
        if (!mounted) return;
        AppSnack.show(
          context,
          message: context.l10n.profileAvatarReadPhotoFailed,
          type: AppSnackType.warning,
        );
        Navigator.of(context).pop();
        return;
      }

      final Uint8List? bytes = await loadAvatarImageBytesForCrop(
        pathForCrop,
        maxDecodeWidth: maxDecodeWidth,
      );
      if (!mounted) return;
      if (bytes == null) {
        AppSnack.show(
          context,
          message: context.l10n.profileAvatarReadPhotoFailed,
          type: AppSnackType.warning,
        );
        Navigator.of(context).pop();
        return;
      }
      setState(() {
        _imageBytes = bytes;
        _preparing = false;
      });
    } catch (_) {
      if (!mounted) return;
      AppSnack.show(
        context,
        message: context.l10n.profileAvatarReadPhotoFailed,
        type: AppSnackType.warning,
      );
      Navigator.of(context).pop();
    }
  }

  void _cancel() {
    AppHaptics.light();
    Navigator.of(context).pop();
  }

  Future<void> _done() async {
    if (_cropping || _preparing || _imageBytes == null) return;
    setState(() => _cropping = true);
    AppHaptics.light();
    _controller.cropCircle();
  }

  Future<void> _handleCropped(CropResult result) async {
    if (!mounted) return;
    switch (result) {
      case CropSuccess(:final croppedImage):
        try {
          final Directory tempDir = await getTemporaryDirectory();
          final String path =
              '${tempDir.path}/avatar_cropped_${DateTime.now().millisecondsSinceEpoch}.jpg';
          await File(path).writeAsBytes(croppedImage);
          if (!mounted) return;
          AppHaptics.medium();
          Navigator.of(context).pop<String>(path);
        } catch (_) {
          if (!mounted) return;
          setState(() => _cropping = false);
          AppSnack.show(
            context,
            message: context.l10n.profileAvatarCropFailed,
            type: AppSnackType.warning,
          );
        }
      case CropFailure():
        if (!mounted) return;
        setState(() => _cropping = false);
        AppSnack.show(
          context,
          message: context.l10n.profileAvatarCropFailed,
          type: AppSnackType.warning,
        );
    }
  }

  Widget _buildCardContent(AppLocalizations l10n) {
    if (_preparing || _imageBytes == null) {
      return KeyedSubtree(
        key: const ValueKey<String>('avatar_crop_prep'),
        child: Center(
          child: Semantics(
            label: l10n.profileAvatarCropLoading,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.profileAvatarCropLoading,
                    textAlign: TextAlign.center,
                    style: AppTypography.cardSubtitle.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return KeyedSubtree(
      key: const ValueKey<String>('avatar_crop_editor'),
      child: Semantics(
        label: l10n.profileAvatarCropEditorSemantic,
        child: Crop(
          image: _imageBytes!,
          controller: _controller,
          withCircleUi: true,
          aspectRatio: 1,
          interactive: true,
          fixCropRect: true,
          maskColor: AppColors.black.withValues(alpha: 0.58),
          baseColor: AppColors.inputFill,
          radius: 0,
          overlayBuilder: _avatarCropGridOverlay,
          cornerDotBuilder: (double size, EdgeAlignment edge) =>
              const SizedBox.shrink(),
          clipBehavior: Clip.hardEdge,
          filterQuality: FilterQuality.medium,
          progressIndicator: const Center(
            child: SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          onCropped: _handleCropped,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final bool canAct = !_preparing && _imageBytes != null;

    return PopScope(
      canPop: !_cropping,
      child: Scaffold(
        backgroundColor: AppColors.panelBackground,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xs,
                  AppSpacing.sm,
                  AppSpacing.xs,
                  AppSpacing.sm,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(
                      width: 88,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: _cropping ? null : _cancel,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.sm,
                            ),
                            minimumSize: const Size(44, 44),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            l10n.profileAvatarCropCancel,
                            style: AppTypography.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w400,
                              fontSize: 17,
                              height: 1.2,
                              letterSpacing: -0.41,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              l10n.profileAvatarCropMoveAndScale,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.textTheme.titleMedium
                                  ?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 17,
                                height: 1.18,
                                letterSpacing: -0.41,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            AnimatedSwitcher(
                              duration: AppMotion.fast,
                              switchInCurve: AppMotion.smooth,
                              switchOutCurve: AppMotion.standardCurve,
                              child: canAct
                                  ? Padding(
                                      key: const ValueKey<String>(
                                        'avatar_crop_hint',
                                      ),
                                      padding: const EdgeInsets.only(
                                        top: 4,
                                      ),
                                      child: Text(
                                        l10n.profileAvatarCropHint,
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography
                                            .textTheme.bodySmall
                                            ?.copyWith(
                                          color: AppColors.textMuted,
                                          fontSize: 13,
                                          height: 1.22,
                                          fontWeight: FontWeight.w400,
                                          letterSpacing: -0.08,
                                        ),
                                      ),
                                    )
                                  : const SizedBox(
                                      key: ValueKey<String>(
                                        'avatar_crop_no_hint',
                                      ),
                                      height: 0,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 88,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: (_cropping || !canAct) ? null : _done,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primaryDark,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.sm,
                            ),
                            minimumSize: const Size(44, 44),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            l10n.profileAvatarCropDone,
                            style: AppTypography.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 17,
                              height: 1.2,
                              letterSpacing: -0.41,
                              color: (_cropping || !canAct)
                                  ? AppColors.textMuted
                                  : AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                thickness: 1,
                color: AppColors.divider.withValues(alpha: 0.85),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusCard),
                      border: Border.all(
                        color: AppColors.divider.withValues(alpha: 0.75),
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: AppColors.shadowLight,
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusCard),
                      child: AnimatedSwitcher(
                        duration: AppMotion.medium,
                        switchInCurve: AppMotion.smooth,
                        switchOutCurve: AppMotion.standardCurve,
                        child: _buildCardContent(l10n),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
