import 'package:chisto_infrastructure/core/theme/app_spacing.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/no_overscroll_overlay_scroll_behavior.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/app_refresh_indicator.dart';
import 'package:feature_profile/src/domain/models/profile_user.dart';
import 'package:feature_profile/src/presentation/screens/profile_points_history_screen.dart';
import 'package:feature_profile/src/presentation/screens/weekly_rankings_screen.dart';
import 'package:feature_profile/src/presentation/widgets/profile_header.dart';
import 'package:feature_profile/src/presentation/widgets/profile_level_points_card.dart';
import 'package:feature_profile/src/presentation/widgets/profile_screen_skeleton.dart';
import 'package:feature_profile/src/presentation/widgets/profile_scroll_bottom_shadow_clipper.dart';
import 'package:feature_profile/src/presentation/widgets/profile_settings_section.dart';
import 'package:feature_profile/src/presentation/widgets/profile_weekly_rank_card.dart';
import 'package:feature_reports/feature_reports.dart';
import 'package:flutter/material.dart';

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
        ProfileHeader(user: user, onProfileUpdated: onProfileUpdated),
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
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => ProfilePointsHistoryScreen(
                                      summaryUser: user,
                                    ),
                                  ),
                                );
                              },
                            ),
                            if (capacityLoadInFlight &&
                                reportCapacity == null) ...<Widget>[
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
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        const WeeklyRankingsScreen(),
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
