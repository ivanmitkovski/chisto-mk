import 'dart:io';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/shared/widgets/organisms/immersive_photo_gallery.dart';
import 'package:chisto_mobile/shared/widgets/atoms/app_button.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

enum PhotoReviewResult { use, retake }

class PhotoReviewSheet extends StatefulWidget {
  const PhotoReviewSheet({super.key, required this.file});

  final XFile file;

  @override
  State<PhotoReviewSheet> createState() => _PhotoReviewSheetState();
}

class _PhotoReviewSheetState extends State<PhotoReviewSheet> {
  late final TransformationController _zoomController;
  TapDownDetails? _doubleTapDetails;

  bool get _isZoomed => _zoomController.value.getMaxScaleOnAxis() > 1.01;

  @override
  void initState() {
    super.initState();
    _zoomController = TransformationController();
  }

  @override
  void dispose() {
    _zoomController.dispose();
    super.dispose();
  }

  void _toggleZoom() {
    final TapDownDetails? details = _doubleTapDetails;
    if (details == null) return;
    if (_isZoomed) {
      _zoomController.value = Matrix4.identity();
      setState(() {});
      return;
    }

    final Offset tapPosition = details.localPosition;
    const double scale = 2.4;
    _zoomController.value = Matrix4.identity()
      ..translateByDouble(
        -tapPosition.dx * (scale - 1),
        -tapPosition.dy * (scale - 1),
        0,
        1,
      )
      ..scaleByDouble(scale, scale, 1, 1);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double sheetHeight = screenHeight * 4 / 5;

    return Semantics(
      label: context.l10n.reportPhotoReviewSemantic,
      child: SizedBox(
        height: sheetHeight,
        child: ReportSheetScaffold(
          title: context.l10n.reportPhotoReviewSheetTitle,
          subtitle: context.l10n.reportPhotoReviewSheetSubtitle,
          trailing: ReportCircleIconButton(
            icon: Icons.close_rounded,
            semanticLabel: context.l10n.reportPhotoReviewCloseSemantic,
            onTap: () async {
              final bool? discard = await showDialog<bool>(
                context: context,
                builder: (BuildContext dialogContext) {
                  return AlertDialog(
                    title: Text(dialogContext.l10n.photoReviewDiscardTitle),
                    content: Text(dialogContext.l10n.photoReviewDiscardBody),
                    actions: <Widget>[
                      AppButton.text(
                        label: dialogContext.l10n.commonKeepEditing,
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                      ),
                      AppButton.destructive(
                        label: dialogContext.l10n.commonDiscard,
                        onPressed: () {
                          Navigator.of(dialogContext).pop(true);
                        },
                        expand: false,
                      ),
                    ],
                  );
                },
              );
              if (discard == true && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          footer: Row(
            children: <Widget>[
              Expanded(
                child: Semantics(
                  button: true,
                  label: context.l10n.reportPhotoReviewRetakeSemantic,
                  child: AppButton.outlined(
                    label: context.l10n.reportPhotoReviewRetake,
                    onPressed: () {
                      Navigator.of(context).pop(PhotoReviewResult.retake);
                    },
                    expand: true,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Semantics(
                  button: true,
                  label: context.l10n.reportPhotoReviewUseSemantic,
                  child: AppButton.primary(
                    label: context.l10n.reportPhotoReviewUsePhoto,
                    onPressed: () {
                      Navigator.of(context).pop(PhotoReviewResult.use);
                    },
                    expand: true,
                  ),
                ),
              ),
            ],
          ),
          child: Semantics(
            label: context.l10n.reportPhotoReviewPreviewSemantic,
            image: true,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.radius22),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radius22),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[AppColors.black, AppColors.black],
                    ),
                  ),
                  child: Stack(
                    children: <Widget>[
                      Positioned.fill(
                        child: GestureDetector(
                          onDoubleTapDown: (TapDownDetails details) {
                            _doubleTapDetails = details;
                          },
                          onDoubleTap: _toggleZoom,
                          child: InteractiveViewer(
                            transformationController: _zoomController,
                            minScale: 1,
                            maxScale: 4,
                            boundaryMargin: const EdgeInsets.all(AppSpacing.xl),
                            child: Center(
                              child: Image.file(
                                File(widget.file.path),
                                fit: BoxFit.contain,
                                frameBuilder:
                                    (
                                      BuildContext context,
                                      Widget child,
                                      int? frame,
                                      bool wasSynchronouslyLoaded,
                                    ) {
                                      if (wasSynchronouslyLoaded) {
                                        return child;
                                      }
                                      return AnimatedOpacity(
                                        opacity: frame == null ? 0 : 1,
                                        duration: AppMotion.medium,
                                        curve: AppMotion.emphasized,
                                        child: child,
                                      );
                                    },
                                errorBuilder:
                                    (
                                      _,
                                      Object error,
                                      StackTrace? stackTrace,
                                    ) => Container(
                                      color: AppColors.inputFill,
                                      child: const Center(
                                        child: Icon(
                                          Icons.image_not_supported_outlined,
                                          color: AppColors.textMuted,
                                          size: 32,
                                        ),
                                      ),
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: AppSpacing.sm,
                        bottom: AppSpacing.sm,
                        child: AnimatedOpacity(
                          opacity: _isZoomed ? 0.72 : 1,
                          duration: AppMotion.fast,
                          child: GalleryGlassPill(
                            child: Text(
                              _isZoomed
                                  ? 'Double-tap to reset zoom'
                                  : 'Pinch or double-tap to inspect',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textOnDark,
                                    letterSpacing: -0.1,
                                  ),
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
        ),
      ),
    );
  }
}
