import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/site_card/site_card_text_utils.dart';
import 'package:chisto_mobile/shared/widgets/primary_button.dart';
import 'package:flutter/material.dart';

/// Title, description (truncated), and primary "Take action" CTA for a feed site card.
class SiteCardBody extends StatefulWidget {
  const SiteCardBody({
    super.key,
    required this.site,
    required this.onTakeAction,
  });

  final PollutionSite site;
  final VoidCallback onTakeAction;

  @override
  State<SiteCardBody> createState() => _SiteCardBodyState();
}

class _SiteCardBodyState extends State<SiteCardBody> {
  String? _cachedTitleTruncated;
  String? _cachedDescTruncated;
  double? _cachedTruncationWidth;
  String? _cachedTitleKey;
  String? _cachedDescKey;

  @override
  void didUpdateWidget(covariant SiteCardBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.site.id != widget.site.id ||
        oldWidget.site.title != widget.site.title ||
        oldWidget.site.description != widget.site.description) {
      _cachedTitleTruncated = null;
      _cachedDescTruncated = null;
      _cachedTruncationWidth = null;
      _cachedTitleKey = null;
      _cachedDescKey = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxWidth = constraints.maxWidth;
        final TextStyle titleStyle = AppTypography.cardTitle.copyWith(
          fontWeight: FontWeight.w700,
        );
        final TextStyle descStyle = AppTypography.cardSubtitle.copyWith(
          color: AppColors.textSecondary,
          height: 1.35,
        );
        final PollutionSite site = widget.site;
        final bool cacheValid =
            _cachedTruncationWidth == maxWidth &&
            _cachedTitleKey == site.title &&
            _cachedDescKey == site.description &&
            _cachedTitleTruncated != null &&
            _cachedDescTruncated != null;
        late final String titleDisplay;
        late final String descDisplay;
        if (cacheValid) {
          titleDisplay = _cachedTitleTruncated!;
          descDisplay = _cachedDescTruncated!;
        } else {
          titleDisplay = truncateSiteCardTextAtWordBoundary(
            site.title,
            style: titleStyle,
            maxWidth: maxWidth,
            maxLines: 1,
          );
          descDisplay = truncateSiteCardTextAtWordBoundary(
            site.description,
            style: descStyle,
            maxWidth: maxWidth,
            maxLines: 2,
          );
          _cachedTitleTruncated = titleDisplay;
          _cachedDescTruncated = descDisplay;
          _cachedTitleKey = site.title;
          _cachedDescKey = site.description;
          _cachedTruncationWidth = maxWidth;
        }
        final String titleNorm = site.title.trim().toLowerCase();
        final String descNorm = site.description.trim().toLowerCase();
        final bool redundant =
            titleNorm.isEmpty || descNorm.isEmpty || titleNorm == descNorm;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: maxWidth,
              child: Text(
                titleDisplay,
                style: titleStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!redundant) ...<Widget>[
              const SizedBox(height: AppSpacing.xs),
              SizedBox(
                width: maxWidth,
                child: Text(
                  descDisplay,
                  style: descStyle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: context.l10n.siteCardTakeActionSemantic,
              onPressed: widget.onTakeAction,
            ),
          ],
        );
      },
    );
  }
}
