import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/cache/report_images_cache.dart' show reportImagesCache, stableCacheKeyForReportImage;
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/reports/presentation/l10n/report_category_l10n.dart';
import 'package:chisto_mobile/features/reports/presentation/l10n/report_status_l10n.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/reports_list/report_mock_store.dart';

class ReportCard extends StatelessWidget {
  const ReportCard({
    super.key,
    required this.report,
    required this.onTap,
    required this.formatDate,
  });

  final MockReport report;
  final VoidCallback onTap;
  final String Function(DateTime) formatDate;

  static bool _isNetworkUrl(String s) =>
      s.startsWith('http://') || s.startsWith('https://');

  static bool _isLocalFile(String s) =>
      !_isNetworkUrl(s) && File(s).existsSync();

  @override
  Widget build(BuildContext context) {
    final List<String> evidencePaths = report.evidenceImagePaths ?? const <String>[];
    final bool hasEvidenceImage = evidencePaths.isNotEmpty &&
        (_isNetworkUrl(evidencePaths.first) || _isLocalFile(evidencePaths.first));

    final String location = report.address ?? report.title;
    final AppLocalizations l10n = context.l10n;
    return Semantics(
      button: true,
      label: l10n.reportCardSemanticLabel(
        report.category.localizedTitle(l10n),
        reportUiStatusShortLabel(l10n, report.status),
        location,
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Material(
          color: AppColors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: Ink(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.panelBackground,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.divider, width: 0.5),
                  boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        child: SizedBox(
                          width: 72,
                          height: 72,
                          child: hasEvidenceImage
                              ? Stack(
                                  fit: StackFit.expand,
                                  children: <Widget>[
                                    _ReportThumbnail(pathOrUrl: evidencePaths.first),
                                    DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: <Color>[
                                            AppColors.black.withValues(
                                              alpha: 0.05,
                                            ),
                                            AppColors.black.withValues(
                                              alpha: 0.24,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Container(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.08,
                                  ),
                                  child: Icon(
                                    Icons.image_outlined,
                                    size: 28,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(
                                  child: Wrap(
                                    spacing: AppSpacing.xs,
                                    runSpacing: AppSpacing.xs,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: <Widget>[
                                      if (report.reportNumber != null)
                                        Text(
                                          report.reportNumber!,
                                          style: AppTypography.cardSubtitle
                                              .copyWith(
                                            fontFeatures: const <FontFeature>[
                                              FontFeature.tabularFigures(),
                                            ],
                                          ),
                                        ),
                                      ReportStatusBadge(status: report.status),
                                      Text(
                                        formatDate(report.createdAt),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.cardSubtitle
                                            .copyWith(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: <Widget>[
                                    if (report.score > 0)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          Icon(
                                            Icons.emoji_events_rounded,
                                            size: AppSpacing.iconSm,
                                            color: AppColors.accentWarning,
                                          ),
                                          const SizedBox(width: AppSpacing.xxs),
                                          Text(
                                            '+${report.score}',
                                            style: AppTypography.chipLabel.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.accentWarning,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    Icon(
                                    Icons.chevron_right_rounded,
                                    size: AppSpacing.iconMd,
                                      color: AppColors.textMuted,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Wrap(
                              spacing: AppSpacing.xs,
                              runSpacing: AppSpacing.xs,
                              children: <Widget>[
                                ReportStatePill(
                                  label: report.category.localizedTitle(context.l10n),
                                  icon: report.category.icon,
                                  tone: ReportSurfaceTone.neutral,
                                ),
                                if (hasEvidenceImage)
                                  const ReportStatePill(
                                    label: 'Photo attached',
                                    icon: Icons.image_outlined,
                                    tone: ReportSurfaceTone.accent,
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              report.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.cardTitle,
                            ),
                            if (report.description.trim() != report.title.trim()) ...[
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                report.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.textTheme.bodySmall!.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.3,
                                ),
                              ),
                            ],
                            if (report.address != null &&
                                report.address!.isNotEmpty &&
                                report.address!.trim() != report.title.trim()) ...[
                              const SizedBox(height: AppSpacing.xxs),
                              Row(
                                children: <Widget>[
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: AppSpacing.iconSm,
                                    color: AppColors.textMuted,
                                  ),
                                  const SizedBox(width: AppSpacing.xxs),
                                  Expanded(
                                    child: Text(
                                      report.address!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.cardSubtitle
                                          .copyWith(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (report.declineReason != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.sm),
                    ReportInfoBanner(
                      title: 'Review note',
                      message: report.declineReason!,
                      icon: Icons.info_outline_rounded,
                      tone: ReportSurfaceTone.warning,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ReportStatusBadge extends StatelessWidget {
  const ReportStatusBadge({super.key, required this.status});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCircle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: status.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            reportUiStatusShortLabel(context.l10n, status),
            style: AppTypography.badgeLabel.copyWith(
              fontSize: 12,
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportThumbnail extends StatelessWidget {
  const _ReportThumbnail({required this.pathOrUrl});

  final String pathOrUrl;

  @override
  Widget build(BuildContext context) {
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: pathOrUrl,
        cacheKey: stableCacheKeyForReportImage(pathOrUrl),
        cacheManager: reportImagesCache,
        fit: BoxFit.cover,
        memCacheWidth: 216,
        memCacheHeight: 216,
        placeholder: (_, __) => Container(
          color: AppColors.inputFill,
          alignment: Alignment.center,
          child: const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (_, __, Object? error) => Container(
          color: AppColors.inputFill,
          alignment: Alignment.center,
          child: const Icon(
            Icons.image_not_supported_outlined,
            color: AppColors.textMuted,
            size: AppSpacing.iconLg,
          ),
        ),
      );
    }
    return Image(
      image: FileImage(File(pathOrUrl)),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: AppColors.inputFill,
        alignment: Alignment.center,
        child: const Icon(
          Icons.image_not_supported_outlined,
          color: AppColors.textMuted,
          size: AppSpacing.iconLg,
        ),
      ),
    );
  }
}
