import 'package:design_system/src/theme/app_colors.dart';
import 'package:design_system/src/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Shared elevation shadows — use instead of ad-hoc [BoxShadow] lists in features.
abstract final class AppShadows {
  const AppShadows._();

  static List<BoxShadow> softCard(ColorScheme colorScheme) => <BoxShadow>[
    BoxShadow(
      color: colorScheme.shadow.withValues(alpha: 0.04),
      blurRadius: AppSpacing.sm,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> card(ColorScheme colorScheme) => <BoxShadow>[
    BoxShadow(
      color: colorScheme.shadow.withValues(alpha: 0.06),
      blurRadius: AppSpacing.md,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: colorScheme.shadow.withValues(alpha: 0.1),
      blurRadius: AppSpacing.lg,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> cardPressed(ColorScheme colorScheme) => <BoxShadow>[
    BoxShadow(
      color: colorScheme.shadow.withValues(alpha: 0.06),
      blurRadius: AppSpacing.sm,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> panel(ColorScheme colorScheme) => <BoxShadow>[
    BoxShadow(
      color: colorScheme.shadow.withValues(alpha: 0.08),
      blurRadius: AppSpacing.lg,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> sheet(ColorScheme colorScheme) => <BoxShadow>[
    BoxShadow(
      color: colorScheme.shadow.withValues(alpha: 0.12),
      blurRadius: AppSpacing.xl,
      offset: const Offset(0, -4),
    ),
  ];

  static List<BoxShadow> floatingPill(ColorScheme colorScheme) => <BoxShadow>[
    BoxShadow(
      color: AppColors.primaryDark.withValues(alpha: 0.12),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> bottomBarLift(ColorScheme colorScheme) => <BoxShadow>[
    BoxShadow(
      color: colorScheme.shadow.withValues(alpha: 0.08),
      blurRadius: 12,
      offset: const Offset(0, -2),
    ),
  ];

  static List<BoxShadow> mediaHero(ColorScheme colorScheme) => <BoxShadow>[
    BoxShadow(
      color: AppColors.primaryDark.withValues(alpha: 0.08),
      blurRadius: 28,
      offset: const Offset(0, 14),
    ),
  ];

  static List<BoxShadow> dialogHero() => <BoxShadow>[
    BoxShadow(
      color: AppColors.black.withValues(alpha: 0.15),
      blurRadius: 40,
      offset: const Offset(0, 16),
    ),
  ];

  static List<BoxShadow> chatBubblePeer() => <BoxShadow>[
    const BoxShadow(
      color: AppColors.shadowLight,
      blurRadius: 6,
      offset: Offset(0, 1),
    ),
  ];

  static List<BoxShadow> chatBubbleOwn() => <BoxShadow>[
    const BoxShadow(
      color: AppColors.shadowLight,
      blurRadius: 3,
      offset: Offset(0, 1),
    ),
  ];

  static List<BoxShadow> chatHighlightPulse(double t) {
    final double a = 0.08 + 0.06 * t;
    return <BoxShadow>[
      BoxShadow(
        color: AppColors.primary.withValues(alpha: a),
        blurRadius: 10 + 4 * t,
        spreadRadius: 0.5,
      ),
    ];
  }

  static List<BoxShadow> chatComposerLift() => <BoxShadow>[
    BoxShadow(
      color: AppColors.shadowLight.withValues(alpha: 0.04),
      blurRadius: 6,
      offset: const Offset(0, -1),
    ),
  ];

  static List<BoxShadow> chatDatePill() => <BoxShadow>[
    BoxShadow(
      color: AppColors.shadowLight.withValues(alpha: 0.04),
      blurRadius: 3,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> chatAttachmentBadge() => <BoxShadow>[
    BoxShadow(
      color: AppColors.black.withValues(alpha: 0.08),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> chatVoiceCancel(Color danger) => <BoxShadow>[
    BoxShadow(
      color: danger.withValues(alpha: 0.18),
      blurRadius: 12,
      spreadRadius: 0,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> qrScannerCorner() => <BoxShadow>[
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.45),
      blurRadius: 6,
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> sitePickerCard({required bool selected}) =>
      <BoxShadow>[
        BoxShadow(
          color: AppColors.black.withValues(alpha: selected ? 0.03 : 0.04),
          blurRadius: selected ? 6 : 10,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> sitePickerListRow() => <BoxShadow>[
    BoxShadow(
      color: AppColors.black.withValues(alpha: 0.03),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> sheetFooterLift() => <BoxShadow>[
    BoxShadow(
      color: AppColors.black.withValues(alpha: 0.06),
      blurRadius: 36,
      offset: const Offset(0, -4),
    ),
  ];

  static List<BoxShadow> fabPrimary() => <BoxShadow>[
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.35),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
    const BoxShadow(
      color: AppColors.shadowLight,
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  static List<BoxShadow> notificationBell(double scale) => <BoxShadow>[
    BoxShadow(
      color: AppColors.shadowLight,
      blurRadius: 10 * scale,
      offset: Offset(0, 3 * scale),
    ),
  ];

  static List<BoxShadow> notificationBadge(double scale) => <BoxShadow>[
    BoxShadow(
      color: AppColors.accentDanger.withValues(alpha: 0.35),
      blurRadius: 8 * scale,
      offset: Offset(0, 2 * scale),
    ),
  ];

  static List<BoxShadow> mapHeatmapRingActive() => <BoxShadow>[
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.35),
      blurRadius: 14,
      spreadRadius: 1,
    ),
  ];

  static List<BoxShadow> mapSiteMarker({
    required bool isSelected,
    required Color statusColor,
  }) => <BoxShadow>[
    if (isSelected)
      BoxShadow(
        color: statusColor.withValues(alpha: 0.45),
        blurRadius: 20,
        spreadRadius: 4,
      ),
    BoxShadow(
      color: AppColors.black.withValues(alpha: isSelected ? 0.28 : 0.18),
      blurRadius: isSelected ? 16 : 8,
      offset: Offset(0, isSelected ? 8 : 4),
    ),
  ];

  static List<BoxShadow> mapClusterDominant(Color dominant) => <BoxShadow>[
    BoxShadow(
      color: dominant.withValues(alpha: 0.3),
      blurRadius: 12,
      spreadRadius: 1,
    ),
    const BoxShadow(
      color: AppColors.shadowLight,
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];

  static List<BoxShadow> mapMarkerGlow(Color color) => <BoxShadow>[
    BoxShadow(
      color: color.withValues(alpha: 0.25),
      blurRadius: 12,
      spreadRadius: 2,
    ),
  ];

  static List<BoxShadow> mapUserLocationPin() => <BoxShadow>[
    BoxShadow(
      color: AppColors.primaryDark.withValues(alpha: 0.4),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> sitePreviewPanel() => <BoxShadow>[
    const BoxShadow(
      color: AppColors.shadowLight,
      blurRadius: 20,
      offset: Offset(0, 6),
    ),
  ];

  static List<BoxShadow> profileAvatarCard() => <BoxShadow>[
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
  ];

  static List<BoxShadow> profileAvatarBadge() => <BoxShadow>[
    BoxShadow(
      color: AppColors.black.withValues(alpha: 0.12),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> profileCropToolbar() => <BoxShadow>[
    const BoxShadow(
      color: AppColors.shadowLight,
      blurRadius: 14,
      offset: Offset(0, 5),
    ),
  ];

  static List<BoxShadow> profileSkeletonCard() => const <BoxShadow>[
    BoxShadow(
      color: AppColors.shadowMedium,
      blurRadius: 14,
      offset: Offset(0, 6),
    ),
  ];

  static List<BoxShadow> locationPickerFab() => <BoxShadow>[
    BoxShadow(
      color: AppColors.black.withValues(alpha: 0.1),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> photoGridSelected() => <BoxShadow>[
    BoxShadow(
      color: AppColors.primaryDark.withValues(alpha: 0.14),
      blurRadius: 12,
      spreadRadius: 0,
      offset: const Offset(0, 4),
    ),
  ];

  /// Empty photo gallery placeholder — fixed ink so IME rebuilds do not shift shadow.
  static List<BoxShadow> photoGridEmptyCard() => <BoxShadow>[
    BoxShadow(
      color: AppColors.black.withValues(alpha: 0.06),
      blurRadius: AppSpacing.md,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: AppColors.black.withValues(alpha: 0.08),
      blurRadius: AppSpacing.lg,
      offset: const Offset(0, 8),
    ),
  ];

  /// Compact add tile in the thumbnail strip — same fixed ink as [photoGridEmptyCard].
  static List<BoxShadow> photoGridCompactAddTile() => <BoxShadow>[
    BoxShadow(
      color: AppColors.black.withValues(alpha: 0.05),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> emphasizedListRow({required bool emphasized}) =>
      <BoxShadow>[
        BoxShadow(
          color: AppColors.black.withValues(alpha: emphasized ? 0.02 : 0.012),
          blurRadius: emphasized ? 14 : 10,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> qrSuccessPanel() => <BoxShadow>[
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.22),
      blurRadius: 24,
      spreadRadius: 0,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> eventDetailElevatedCard() => const <BoxShadow>[
    BoxShadow(
      color: AppColors.shadowMedium,
      blurRadius: 10,
      offset: Offset(0, 2),
    ),
  ];

  static List<BoxShadow> eventDetailModule() => <BoxShadow>[
    const BoxShadow(
      color: AppColors.shadowLight,
      blurRadius: 8,
      offset: Offset(0, 1),
    ),
  ];

  static List<BoxShadow> eventStickyCta({required double alpha}) => <BoxShadow>[
    BoxShadow(
      color: AppColors.black.withValues(alpha: alpha),
      blurRadius: 12,
      offset: const Offset(0, -4),
    ),
  ];

  static List<BoxShadow> photoReviewSheet() => <BoxShadow>[
    BoxShadow(
      color: AppColors.black.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> reportModal() => const <BoxShadow>[
    BoxShadow(
      color: AppColors.shadowMedium,
      blurRadius: 24,
      offset: Offset(0, 10),
    ),
  ];

  static List<BoxShadow> reportSubmittedHero() => <BoxShadow>[
    BoxShadow(
      color: AppColors.black.withValues(alpha: 0.08),
      blurRadius: 32,
      offset: const Offset(0, 12),
    ),
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.06),
      blurRadius: 24,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> reportSubmittedIcon() => <BoxShadow>[
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.35),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> cleanupEvidenceThumbnail() => <BoxShadow>[
    BoxShadow(
      color: AppColors.black.withValues(alpha: 0.12),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];
}
