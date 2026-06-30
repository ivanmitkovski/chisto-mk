part of 'package:feature_events/src/presentation/organizer_checkin/organizer_checkin_screen.dart';

extension _OrganizerCheckInAttendeeSlivers on _OrganizerCheckInScreenState {
  List<Widget> _buildCheckedInAttendeeSlivers(
    BuildContext context,
    TextTheme textTheme,
    List<CheckedInAttendee> attendees,
    AppLocalizations l10n,
  ) {
    return <Widget>[
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                context.l10n.eventsOrganizerCheckedInHeading,
                style: AppTypography.eventsCalendarMonthTitle(
                  textTheme,
                ).copyWith(color: AppColors.textPrimary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Text(
                  '${attendees.length}',
                  style: AppTypography.badgeLabel(textTheme).copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      if (attendees.isEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.lg,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.xl,
                horizontal: AppSpacing.lg,
              ),
              decoration: BoxDecoration(
                color: AppColors.inputFill.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                border: Border.all(
                  color: AppColors.divider.withValues(alpha: 0.7),
                ),
              ),
              child: AppEmptyState(
                icon: CupertinoIcons.person_2,
                title: context.l10n.eventsOrganizerEmptyListTitle,
                subtitle: context.l10n.eventsOrganizerEmptyListSubtitle,
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((
              BuildContext context,
              int index,
            ) {
              final CheckedInAttendee attendee = attendees[index];
              return CheckedInRow(
                attendee: attendee,
                onRemove: () =>
                    unawaited(_attendeeCoordinator.removeAttendee(attendee)),
              );
            }, childCount: attendees.length),
          ),
        ),

      SliverToBoxAdapter(
        child: SizedBox(
          height: AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
        ),
      ),
    ];
  }
}
