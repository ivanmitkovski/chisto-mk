import 'package:design_system/design_system.dart';
import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:feature_home/src/presentation/widgets/site_card/site_card_body.dart';
import 'package:feature_home/src/presentation/widgets/site_card/site_card_engagement_bar.dart';
import 'package:flutter/material.dart';

/// Engagement bar + body column extracted from [PollutionSiteCard].
class PollutionSiteCardContent extends StatelessWidget {
  const PollutionSiteCardContent({
    super.key,
    required this.site,
    required this.isUpvoted,
    required this.upvoteCount,
    required this.commentCount,
    required this.shareCount,
    required this.isSaved,
    required this.saveIconScale,
    required this.isUpvoteInFlight,
    required this.isSaveInFlight,
    required this.isShareInFlight,
    required this.onUpvoteTap,
    required this.onUpvoteCountTap,
    required this.onCommentsTap,
    required this.onShareTap,
    required this.onSaveTap,
    required this.onTakeAction,
    required this.buildAnimatedCount,
  });

  final PollutionSite site;
  final bool isUpvoted;
  final int upvoteCount;
  final int commentCount;
  final int shareCount;
  final bool isSaved;
  final double saveIconScale;
  final bool isUpvoteInFlight;
  final bool isSaveInFlight;
  final bool isShareInFlight;
  final Future<void> Function() onUpvoteTap;
  final Future<void> Function() onUpvoteCountTap;
  final VoidCallback onCommentsTap;
  final VoidCallback onShareTap;
  final VoidCallback onSaveTap;
  final VoidCallback onTakeAction;
  final Widget Function(int value, TextStyle style) buildAnimatedCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SiteCardEngagementBar(
            siteTitle: site.title,
            isUpvoted: isUpvoted,
            upvoteCount: upvoteCount,
            commentCount: commentCount,
            shareCount: shareCount,
            isSaved: isSaved,
            saveIconScale: saveIconScale,
            isUpvoteInFlight: isUpvoteInFlight,
            isSaveInFlight: isSaveInFlight,
            isShareInFlight: isShareInFlight,
            onUpvoteTap: onUpvoteTap,
            onUpvoteCountTap: onUpvoteCountTap,
            onCommentsTap: onCommentsTap,
            onShareTap: onShareTap,
            onSaveTap: onSaveTap,
            buildAnimatedCount: buildAnimatedCount,
          ),
          const SizedBox(height: AppSpacing.sm),
          SiteCardBody(site: site, onTakeAction: onTakeAction),
        ],
      ),
    );
  }
}
