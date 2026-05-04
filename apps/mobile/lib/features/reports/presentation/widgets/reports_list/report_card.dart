import 'dart:io';

import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/reports/presentation/theme/report_tokens.dart';
import 'package:chisto_mobile/features/reports/presentation/l10n/report_category_l10n.dart';
import 'package:chisto_mobile/features/reports/presentation/l10n/report_status_l10n.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/reports_list/report_card_status_badge.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/reports_list/report_card_thumbnail.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/reports_list/report_sheet_view_model.dart';

export 'report_card_status_badge.dart';

class ReportCard extends StatefulWidget {
  const ReportCard({
    super.key,
    required this.report,
    required this.onTap,
    required this.formatDate,
  });

  final ReportSheetViewModel report;
  final VoidCallback onTap;
  final String Function(DateTime) formatDate;

  @override
  State<ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<ReportCard> {
  bool _pressed = false;

  static bool _isNetworkUrl(String s) =>
      s.startsWith('http://') || s.startsWith('https://');

  static bool _isLocalFile(String s) =>
      !_isNetworkUrl(s) && File(s).existsSync();

  @override
  Widget build(BuildContext context) {
    final ReportSheetViewModel report = widget.report;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<String> evidencePaths =
        report.evidenceImagePaths ?? const <String>[];
    final bool hasEvidenceImage =
        evidencePaths.isNotEmpty &&
        (_isNetworkUrl(evidencePaths.first) ||
            _isLocalFile(evidencePaths.first));

    final String location = report.address ?? report.title;
    final AppLocalizations l10n = context.l10n;
    return RepaintBoundary(
      child: Semantics(
        button: true,
        label: l10n.reportCardSemanticLabel(
          report.category.localizedTitle(l10n),
          reportUiStatusShortLabel(l10n, report.status),
          location,
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: AnimatedScale(
            scale: _pressed ? 0.98 : 1,
            duration: AppMotion.fast,
            curve: AppMotion.emphasized,
            child: Material(
            color: AppColors.transparent,
            child: InkWell(
              onTapDown: (_) => setState(() => _pressed = true),
              onTapCancel: () => setState(() => _pressed = false),
              onTap: () {
                setState(() => _pressed = false);
                widget.onTap();
              },
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: ReportTokens.listCardMinTapHeight,
                ),
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
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                            child: SizedBox(
                              width: 72,
                              height: 72,
                              child: hasEvidenceImage
                                  ? Stack(
                                      fit: StackFit.expand,
                                      children: <Widget>[
                                        ReportCardThumbnail(
                                          pathOrUrl: evidencePaths.first,
                                        ),
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
                                                    fontFeatures:
                                                        const <FontFeature>[
                                                          FontFeature.tabularFigures(),
                                                        ],
                                                  ),
                                            ),
                                          ReportStatusBadge(
                                            status: report.status,
                                          ),
                                          Text(
                                            widget.formatDate(report.createdAt),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style:
                                                AppTypography.reportsBadgeLabel(
                                                  textTheme,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
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
                                              const SizedBox(
                                                width: AppSpacing.xxs,
                                              ),
                                              Text(
                                                '+${report.score}',
                                                style:
                                                    AppTypography.reportsRowValueStrong(
                                                      textTheme,
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
                                      label: report.category.localizedTitle(
                                        context.l10n,
                                      ),
                                      icon: report.category.icon,
                                      tone: ReportSurfaceTone.neutral,
                                    ),
                                    if (report.isOptimistic)
                                      Opacity(
                                        opacity: 0.55,
                                        child: ReportStatePill(
                                          label: l10n.reportListOptimisticPill,
                                          icon: Icons.cloud_upload_outlined,
                                          tone: ReportSurfaceTone.accent,
                                        ),
                                      ),
                                    if (hasEvidenceImage)
                                      ReportStatePill(
                                        label:
                                            l10n.reportDetailPhotoAttachedPill,
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
                                if (report.description.trim() !=
                                    report.title.trim()) ...[
                                  const SizedBox(height: AppSpacing.xxs),
                                  Text(
                                    report.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.textTheme.bodySmall!
                                        .copyWith(
                                          color: AppColors.textSecondary,
                                          height: 1.3,
                                        ),
                                  ),
                                ],
                                if (report.address != null &&
                                    report.address!.isNotEmpty &&
                                    report.address!.trim() !=
                                        report.title.trim()) ...[
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
                                          style:
                                              AppTypography.reportsBadgeLabel(
                                                textTheme,
                                              ),
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
                          title: l10n.reportCardDeclineNoteTitle,
                          message: report.declineReason!,
                          icon: Icons.info_outline_rounded,
                          tone: ReportSurfaceTone.danger,
                        ),
                      ],
                    ],
                  ),
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
