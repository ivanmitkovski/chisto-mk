part of '../report_surface_primitives.dart';

class _ReportSurfacePalette {
  const _ReportSurfacePalette({
    required this.background,
    required this.foreground,
    required this.border,
    required this.iconBackground,
  });

  final Color background;
  final Color foreground;
  final Color border;
  final Color iconBackground;

  factory _ReportSurfacePalette.fromTone(
    ReportSurfaceTone tone, {
    bool emphasized = false,
  }) {
    switch (tone) {
      case ReportSurfaceTone.accent:
        return _ReportSurfacePalette(
          background: emphasized
              ? AppColors.primaryDark
              : AppColors.primary.withValues(alpha: 0.1),
          foreground: emphasized ? AppColors.white : AppColors.primaryDark,
          border: emphasized
              ? AppColors.primaryDark
              : AppColors.primaryDark.withValues(alpha: 0.18),
          iconBackground: emphasized
              ? AppColors.white.withValues(alpha: 0.16)
              : AppColors.primary.withValues(alpha: 0.16),
        );
      case ReportSurfaceTone.success:
        return const _ReportSurfacePalette(
          background: AppColors.reportBannerSuccessBackground,
          foreground: AppColors.primaryDark,
          border: AppColors.reportBannerSuccessBorder,
          iconBackground: AppColors.reportBannerSuccessIconBackground,
        );
      case ReportSurfaceTone.warning:
        return const _ReportSurfacePalette(
          background: AppColors.reportBannerWarningBackground,
          foreground: AppColors.accentWarningDark,
          border: AppColors.reportBannerWarningBorder,
          iconBackground: AppColors.reportBannerWarningIconBackground,
        );
      case ReportSurfaceTone.danger:
        return const _ReportSurfacePalette(
          background: AppColors.reportBannerDangerBackground,
          foreground: AppColors.accentDanger,
          border: AppColors.reportBannerDangerBorder,
          iconBackground: AppColors.reportBannerDangerIconBackground,
        );
      case ReportSurfaceTone.neutral:
        return _ReportSurfacePalette(
          background: AppColors.inputFill,
          foreground: AppColors.textSecondary,
          border: AppColors.divider.withValues(alpha: 0.8),
          iconBackground: AppColors.panelBackground,
        );
    }
  }
}
