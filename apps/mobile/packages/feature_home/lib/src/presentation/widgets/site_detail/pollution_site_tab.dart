import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:feature_home/src/presentation/utils/site_resolution_helpers.dart';
import 'package:feature_home/src/presentation/widgets/site_detail/cleanup_evidence_gallery_section.dart';
import 'package:feature_home/src/presentation/widgets/site_detail/site_detail_widgets.dart';
import 'package:flutter/material.dart';

class PollutionSiteTab extends StatefulWidget {
  const PollutionSiteTab({
    super.key,
    required this.site,
    required this.onTakeAction,
    this.onUpvoteTap,
    this.isUpvotePending = false,
    this.onScoreTap,
    this.onCommentsTap,
    this.onParticipantsTap,
    this.onDistanceTap,
    this.onReportedTap,
    this.onSaveTap,
    this.onReportTap,
    this.onShareTap,
    this.isReported = false,
    this.isSaved = false,
  });

  final PollutionSite site;
  final VoidCallback onTakeAction;
  final Future<void> Function()? onUpvoteTap;
  final bool isUpvotePending;
  final VoidCallback? onScoreTap;
  final VoidCallback? onCommentsTap;
  final VoidCallback? onParticipantsTap;
  final VoidCallback? onDistanceTap;
  final VoidCallback? onReportedTap;
  final VoidCallback? onSaveTap;
  final VoidCallback? onReportTap;
  final VoidCallback? onShareTap;
  final bool isReported;
  final bool isSaved;

  @override
  State<PollutionSiteTab> createState() => _PollutionSiteTabState();
}

class _PollutionSiteTabState extends State<PollutionSiteTab> {
  late bool _isSaved;

  bool get _isResolved => isPollutionSiteResolved(widget.site);

  bool get _hasPendingResolution => hasMyPendingResolution(widget.site);

  @override
  void initState() {
    super.initState();
    _isSaved = widget.isSaved;
  }

  @override
  void didUpdateWidget(covariant PollutionSiteTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSaved != widget.isSaved) {
      _isSaved = widget.isSaved;
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final double bottomSafe = MediaQuery.of(context).padding.bottom;
    final double ctaHeight = 56 + AppSpacing.md * 2 + bottomSafe;

    return Stack(
      children: <Widget>[
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            ctaHeight + AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (_isResolved) ...<Widget>[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          context.l10n.siteDetailResolvedBanner,
                          style: AppTypography.cardSubtitle(textTheme).copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              DetailHeroCarousel(site: widget.site),
              const SizedBox(height: AppSpacing.md),
              SiteStatsRow(
                site: widget.site,
                isUpvotePending: widget.isUpvotePending,
                onUpvoteTap: widget.onUpvoteTap,
                onScoreTap: widget.onScoreTap,
                onCommentsTap: widget.onCommentsTap,
                onParticipantsTap: widget.onParticipantsTap,
                onShareTap: widget.onShareTap,
                onDistanceTap: widget.onDistanceTap,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                widget.site.title,
                style: AppTypography.cardTitle(
                  textTheme,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                widget.site.description,
                style: AppTypography.cardSubtitle(
                  textTheme,
                ).copyWith(height: 1.45),
              ),
              const SizedBox(height: AppSpacing.md),
              if (widget.site.displayFirstReport != null) ...<Widget>[
                SiteReportedRow(
                  reporterName: widget.site.displayFirstReport!.reporterName,
                  reporterIsDeleted:
                      widget.site.displayFirstReport!.reporterIsDeleted,
                  reportedAgo: widget.site.displayFirstReport!.reportedAgo,
                  reporterAvatarUrl:
                      widget.site.displayFirstReport!.reporterAvatarUrl,
                  onTap: widget.onReportedTap,
                ),
              ],
              if (_isResolved) ...<Widget>[
                const SizedBox(height: AppSpacing.lg),
                CleanupEvidenceGallerySection(
                  key: ValueKey<String>('cleanup-evidence-${widget.site.id}'),
                  siteId: widget.site.id,
                ),
              ],
              if (_hasPendingResolution) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                AppInlineBanner(
                  message: context.l10n.siteDetailCleanupUnderReviewBanner,
                  tone: AppInlineBannerTone.info,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              SiteInfoCard(onTap: widget.onTakeAction),
              const SizedBox(height: AppSpacing.md),
              SiteQuickActions(
                isSaved: _isSaved,
                isReported: widget.isReported,
                onSaveTap: () {
                  setState(() => _isSaved = !_isSaved);
                  widget.onSaveTap?.call();
                },
                onReportTap: widget.onReportTap ?? () {},
                onShareTap: widget.onShareTap ?? () {},
              ),
            ],
          ),
        ),
        if (_hasPendingResolution)
          StickyBottomCTA(
            label: context.l10n.siteDetailCleanupUnderReviewCta,
            onPressed: null,
          )
        else
          StickyBottomCTA(
            label: _isResolved
                ? context.l10n.siteDetailAddCleanupPhotoCta
                : context.l10n.pollutionSiteTabTakeAction,
            onPressed: widget.onTakeAction,
          ),
      ],
    );
  }
}
