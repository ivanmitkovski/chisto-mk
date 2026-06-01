part of 'app_surface_primitives.dart';

class _AppSurfacePalette {
  const _AppSurfacePalette({
    required this.background,
    required this.foreground,
    required this.border,
    required this.iconBackground,
  });

  factory _AppSurfacePalette.fromTone(
    AppSurfaceTone tone, {
    bool emphasized = false,
  }) {
    switch (tone) {
      case AppSurfaceTone.accent:
        return _AppSurfacePalette(
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
      case AppSurfaceTone.success:
        return const _AppSurfacePalette(
          background: AppColors.reportBannerSuccessBackground,
          foreground: AppColors.primaryDark,
          border: AppColors.reportBannerSuccessBorder,
          iconBackground: AppColors.reportBannerSuccessIconBackground,
        );
      case AppSurfaceTone.warning:
        return const _AppSurfacePalette(
          background: AppColors.reportBannerWarningBackground,
          foreground: AppColors.accentWarningDark,
          border: AppColors.reportBannerWarningBorder,
          iconBackground: AppColors.reportBannerWarningIconBackground,
        );
      case AppSurfaceTone.danger:
        return const _AppSurfacePalette(
          background: AppColors.reportBannerDangerBackground,
          foreground: AppColors.accentDanger,
          border: AppColors.reportBannerDangerBorder,
          iconBackground: AppColors.reportBannerDangerIconBackground,
        );
      case AppSurfaceTone.neutral:
        return _AppSurfacePalette(
          background: AppColors.inputFill,
          foreground: AppColors.textSecondary,
          border: AppColors.divider.withValues(alpha: 0.8),
          iconBackground: AppColors.panelBackground,
        );
    }
  }

  final Color background;
  final Color foreground;
  final Color border;
  final Color iconBackground;
}
