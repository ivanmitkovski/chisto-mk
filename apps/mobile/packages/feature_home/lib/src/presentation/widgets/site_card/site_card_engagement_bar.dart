import 'package:chisto_infrastructure/core/assets/app_assets.dart';
import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_home/src/presentation/widgets/site_card/site_engagement_animated_number.dart';
import 'package:feature_home/src/presentation/widgets/site_card/site_upvote_affordance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Upvote, comments, share, and save row for a feed site card.
class SiteCardEngagementBar extends StatelessWidget {
  const SiteCardEngagementBar({
    super.key,
    required this.siteTitle,
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
    required this.buildAnimatedCount,
  });

  final String siteTitle;
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
  final Widget Function(int value, TextStyle style) buildAnimatedCount;

  static const double _counterMinWidth = 28;
  static const double _actionIconSize = 24;
  static const double _actionCountFontSize = 13;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final TextStyle countStyle = AppTypography.chipLabel(textTheme).copyWith(
      fontSize: _actionCountFontSize,
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w600,
    );

    return Row(
      children: <Widget>[
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  height: 44,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      SiteUpvoteAffordance(
                        variant: SiteUpvoteAffordanceVariant.barIcon,
                        isUpvoted: isUpvoted,
                        isBusy: isUpvoteInFlight,
                        semanticsLabel: isUpvoted
                            ? context.l10n.siteCardSemanticRemoveUpvote(
                                siteTitle,
                              )
                            : context.l10n.siteCardSemanticUpvote(siteTitle),
                        onPressed: onUpvoteTap,
                      ),
                      const SizedBox(width: 4),
                      Semantics(
                        button: true,
                        label: context.l10n
                            .siteCardSemanticUpvotesOpenSupporters(
                              upvoteCount,
                              siteTitle,
                            ),
                        child: GestureDetector(
                          onTap: () async {
                            await onUpvoteCountTap();
                          },
                          behavior: HitTestBehavior.opaque,
                          child: SizedBox(
                            width: _counterMinWidth,
                            height: 44,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: SiteEngagementAnimatedNumber(
                                value: upvoteCount,
                                style: countStyle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Semantics(
                  button: true,
                  label: context.l10n.siteCardSemanticCommentsOnSite(
                    commentCount,
                    siteTitle,
                  ),
                  child: GestureDetector(
                    onTap: onCommentsTap,
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      height: 44,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const SizedBox(
                            width: 44,
                            height: 44,
                            child: Center(
                              child: Icon(
                                Icons.mode_comment_outlined,
                                size: _actionIconSize,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: _counterMinWidth,
                            height: 44,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: buildAnimatedCount(
                                commentCount,
                                countStyle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Semantics(
                  button: true,
                  label: context.l10n.siteCardSemanticSharesOnSite(
                    shareCount,
                    siteTitle,
                  ),
                  child: GestureDetector(
                    onTap: isShareInFlight ? null : onShareTap,
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      height: 44,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          SizedBox(
                            width: 44,
                            height: 44,
                            child: Center(
                              child: SvgPicture.asset(
                                AppAssets.cardShare,
                                width: _actionIconSize,
                                height: _actionIconSize,
                                colorFilter: const ColorFilter.mode(
                                  AppColors.textPrimary,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: _counterMinWidth,
                            height: 44,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: buildAnimatedCount(shareCount, countStyle),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Semantics(
          button: true,
          label: isSaved
              ? context.l10n.siteCardSemanticUnsaveSite(siteTitle)
              : context.l10n.siteCardSemanticSaveSite(siteTitle),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: isSaveInFlight ? null : onSaveTap,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Align(
                alignment: Alignment.centerRight,
                child: AnimatedOpacity(
                  opacity: isSaveInFlight ? 0.42 : 1,
                  duration: const Duration(milliseconds: 180),
                  curve: AppMotion.emphasized,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 180),
                    curve: AppMotion.emphasized,
                    scale: saveIconScale,
                    child: Icon(
                      isSaved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      size: _actionIconSize,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
