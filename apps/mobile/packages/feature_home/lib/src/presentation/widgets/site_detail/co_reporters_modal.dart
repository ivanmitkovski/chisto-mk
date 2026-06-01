import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_avatar.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_home/src/domain/models/co_reporter_profile.dart';
import 'package:flutter/material.dart';

class CoReportersModal extends StatelessWidget {
  const CoReportersModal({super.key, required this.reporters});

  final List<CoReporterProfile> reporters;

  static Future<void> show(
    BuildContext context,
    List<CoReporterProfile> reporters,
  ) {
    if (reporters.isEmpty) return Future<void>.value();
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: AppColors.panelBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusSheet),
        ),
      ),
      builder: (BuildContext context) => CoReportersModal(reporters: reporters),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) {
        return CustomScrollView(
          controller: scrollController,
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Center(
                      child: Container(
                        width: AppSpacing.sheetHandle,
                        height: AppSpacing.sheetHandleHeight,
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusXs,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      context.l10n.siteDetailCoReportersTitle,
                      style: AppTypographySurfaces.homeCoReportersTitle(
                        Theme.of(context).textTheme,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.siteDetailCoReportersSubtitle(
                        reporters.length,
                      ),
                      style: AppTypographySurfaces.homeCoReportersSubtitle(
                        Theme.of(context).textTheme,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate((
                BuildContext context,
                int index,
              ) {
                final CoReporterProfile row = reporters[index];
                return ListTile(
                  leading: AppAvatar(
                    name: row.displayName,
                    size: 40,
                    fontSize: 14,
                    imageUrl: row.avatarUrl,
                  ),
                  title: Text(row.displayName),
                );
              }, childCount: reporters.length),
            ),
          ],
        );
      },
    );
  }
}
