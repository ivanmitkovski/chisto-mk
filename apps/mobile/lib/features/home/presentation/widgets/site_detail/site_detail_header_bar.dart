import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/shared/widgets/organisms/app_header_bar.dart';
import 'package:flutter/material.dart';

/// Title row for [PollutionSiteDetailScreen].
class SiteDetailHeaderBar extends StatelessWidget {
  const SiteDetailHeaderBar({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => AppHeaderBar(title: title);
}

/// Tab strip for pollution site vs cleaning events.
class SiteDetailTabBar extends StatelessWidget {
  const SiteDetailTabBar({super.key, this.showHistoryTab = true});

  final bool showHistoryTab;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        border: Border(
          bottom: BorderSide(
            color: AppColors.divider.withValues(alpha: 0.6),
            width: 0.5,
          ),
        ),
      ),
      child: TabBar(
        indicatorColor: AppColors.primaryDark,
        indicatorWeight: 2.5,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: AppColors.textMuted,
        labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        labelStyle: AppTypography.chipLabel.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        unselectedLabelStyle: AppTypography.chipLabel.copyWith(
          fontWeight: FontWeight.w400,
          color: AppColors.textMuted,
        ),
        tabs: <Widget>[
          Tab(text: context.l10n.siteDetailTabPollutionSite),
          Tab(text: context.l10n.siteDetailTabCleaningEvents),
          if (showHistoryTab) Tab(text: context.l10n.siteDetailTabHistory),
        ],
      ),
    );
  }
}
