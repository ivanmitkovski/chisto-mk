import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/profile/domain/models/profile_user.dart';
import 'package:chisto_mobile/features/profile/presentation/screens/profile_points_history_screen.dart';
import 'package:chisto_mobile/features/profile/presentation/screens/weekly_rankings_screen.dart';
import 'package:chisto_mobile/features/profile/presentation/widgets/profile_header.dart';
import 'package:chisto_mobile/features/profile/presentation/widgets/profile_scroll_bottom_shadow_clipper.dart';
import 'package:chisto_mobile/features/profile/presentation/widgets/profile_level_points_card.dart';
import 'package:chisto_mobile/features/profile/presentation/widgets/profile_screen_skeleton.dart';
import 'package:chisto_mobile/features/profile/presentation/widgets/profile_settings_section.dart';
import 'package:chisto_mobile/features/profile/presentation/widgets/profile_weekly_rank_card.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_capacity.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/report_capacity_summary_card.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_refresh_indicator.dart';
import 'package:chisto_mobile/shared/widgets/no_overscroll_overlay_scroll_behavior.dart';

/// Scrollable profile home content below the gradient header.
class ProfileAuthenticatedBody extends StatelessWidget {
  const ProfileAuthenticatedBody({
    super.key,
    required this.user,
    required this.languageListSubtitle,
    required this.capacityLoadInFlight,
    required this.reportCapacity,
    required this.onRefresh,
    required this.onProfileUpdated,
    required this.onGeneralInfoTap,
    required this.onLanguageTap,
    required this.onPasswordTap,
  });

  final ProfileUser user;
  final String languageListSubtitle;
  final bool capacityLoadInFlight;
  final ReportCapacity? reportCapacity;
  final Future<void> Function() onRefresh;
  final void Function(ProfileUser) onProfileUpdated;
  final Future<void> Function() onGeneralInfoTap;
  final VoidCallback onLanguageTap;
  final VoidCallback onPasswordTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ProfileHeader(
          user: user,
          onProfileUpdated: onProfileUpdated,
        ),
        Expanded(
          child: ClipRect(
            clipper: const ProfileScrollBottomShadowClipper(
              bottomExtension: kProfileScrollBottomShadowExtension,
            ),
            child: ScrollConfiguration(
              behavior: const NoOverscrollOverlayScrollBehavior(),
              child: AppRefreshIndicator(
                onRefresh: onRefresh,
                child: CustomScrollView(
                  clipBehavior: Clip.none,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: <Widget>[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.xl + AppSpacing.lg,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            ProfileLevelAndPointsCard(
                              user: user,
                              onOpenPointsHistory: () {
                                AppHaptics.softTransition();
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => ProfilePointsHistoryScreen(
                                      summaryUser: user,
                                    ),
                                  ),
                                );
                              },
                            ),
                            if (capacityLoadInFlight && reportCapacity == null) ...<Widget>[
                              const SizedBox(height: AppSpacing.md),
                              const ProfileReportCreditsSkeleton(),
                            ] else if (reportCapacity != null) ...<Widget>[
                              const SizedBox(height: AppSpacing.md),
                              ReportCapacitySummaryCard(
                                capacity: reportCapacity!,
                              ),
                            ],
                            const SizedBox(height: AppSpacing.md),
                            ProfileWeeklyRankCard(
                              user: user,
                              onViewRankings: () {
                                AppHaptics.softTransition();
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const WeeklyRankingsScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            ProfileSettingsSection(
                              languageListSubtitle: languageListSubtitle,
                              onGeneralInfoTap: onGeneralInfoTap,
                              onLanguageTap: onLanguageTap,
                              onPasswordTap: onPasswordTap,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
