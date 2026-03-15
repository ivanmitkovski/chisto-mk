import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/site_detail/site_detail_widgets.dart';

class PollutionSiteTab extends StatefulWidget {
  const PollutionSiteTab({
    super.key,
    required this.site,
    required this.onTakeAction,
    this.onScoreTap,
    this.onCommentsTap,
    this.onParticipantsTap,
    this.onDistanceTap,
    this.onReportedTap,
    this.onSaveTap,
    this.onReportTap,
    this.onShareTap,
    this.isReported = false,
  });

  final PollutionSite site;
  final VoidCallback onTakeAction;
  final VoidCallback? onScoreTap;
  final VoidCallback? onCommentsTap;
  final VoidCallback? onParticipantsTap;
  final VoidCallback? onDistanceTap;
  final VoidCallback? onReportedTap;
  final VoidCallback? onSaveTap;
  final VoidCallback? onReportTap;
  final VoidCallback? onShareTap;
  final bool isReported;

  @override
  State<PollutionSiteTab> createState() => _PollutionSiteTabState();
}

class _PollutionSiteTabState extends State<PollutionSiteTab> {
  bool _isSaved = false;

  @override
  Widget build(BuildContext context) {
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
              DetailHeroCarousel(site: widget.site),
              const SizedBox(height: AppSpacing.md),
              SiteStatsRow(
                site: widget.site,
                onScoreTap: widget.onScoreTap,
                onCommentsTap: widget.onCommentsTap,
                onParticipantsTap: widget.onParticipantsTap,
                onDistanceTap: widget.onDistanceTap,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                widget.site.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                widget.site.description,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(height: 1.45),
              ),
              const SizedBox(height: AppSpacing.md),
              if (widget.site.firstReport != null) ...<Widget>[
                SiteReportedRow(
                  reporterName: widget.site.firstReport!.reporterName,
                  reportedAgo: widget.site.firstReport!.reportedAgo,
                  onTap: widget.onReportedTap,
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
        StickyBottomCTA(label: 'Take action', onPressed: widget.onTakeAction),
      ],
    );
  }
}
