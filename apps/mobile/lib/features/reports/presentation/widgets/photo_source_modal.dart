import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Modal for choosing photo source (camera or gallery).
Future<ImageSource?> showPhotoSourceModal(BuildContext context) async {
  return showCupertinoModalPopup<ImageSource>(
    context: context,
    builder: (BuildContext context) {
      return ReportSheetScaffold(
        title: 'Add photo',
        subtitle: 'Choose how to add the first photo.',
        trailing: ReportCircleIconButton(
          icon: Icons.close_rounded,
          semanticLabel: 'Close',
          onTap: () => Navigator.of(context).pop(),
        ),
        maxHeightFactor: 0.7,
        showHeaderDivider: false,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xs,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'You can review the photo before it is added.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                  height: 1.35,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _PhotoSourceTile(
                icon: Icons.camera_alt_rounded,
                label: 'Take photo',
                subtitle: 'Capture a clear overview right now.',
                badgeLabel: 'Best choice',
                emphasized: true,
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              const SizedBox(height: AppSpacing.sm),
              _PhotoSourceTile(
                icon: Icons.photo_library_rounded,
                label: 'Choose from library',
                subtitle: 'Use a photo already on your device.',
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _PhotoSourceTile extends StatelessWidget {
  const _PhotoSourceTile({
    this.icon = Icons.photo_outlined,
    this.label = '',
    this.subtitle = '',
    this.onTap = _noop,
    String? badgeLabel,
    bool emphasized = false,
    String? helperBadge,
    ReportSurfaceTone? tone,
  }) : badgeLabel = badgeLabel ?? helperBadge,
       emphasized = emphasized || tone == ReportSurfaceTone.accent;

  static void _noop() {}

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final String? badgeLabel;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final Color surfaceColor = emphasized
        ? AppColors.primary.withValues(alpha: 0.08)
        : AppColors.inputFill;
    final Color borderColor = emphasized
        ? AppColors.primaryDark.withValues(alpha: 0.18)
        : AppColors.divider.withValues(alpha: 0.9);
    final Color iconBackground = emphasized
        ? AppColors.primary.withValues(alpha: 0.16)
        : AppColors.panelBackground;
    final Color chevronBackground = emphasized
        ? AppColors.primary.withValues(alpha: 0.12)
        : AppColors.panelBackground;
    final Color chevronColor = emphasized
        ? AppColors.primaryDark
        : AppColors.textMuted;

    return Semantics(
      button: true,
      label: label,
      hint: subtitle,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: borderColor),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: emphasized ? 0.02 : 0.012,
                  ),
                  blurRadius: emphasized ? 14 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: emphasized
                        ? AppColors.primaryDark
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              label,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                            ),
                          ),
                          if (badgeLabel != null)
                            ReportStatePill(
                              label: badgeLabel!,
                              tone: ReportSurfaceTone.accent,
                              emphasized: true,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: chevronBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: chevronColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
