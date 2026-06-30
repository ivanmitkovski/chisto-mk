import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Joiners first so a short stack shows volunteers before the organizer.
/// [merged] is expected to be ordered organizer-first from [mergeParticipantPreviews].
List<AttendeePreview> orderPreviewsForAvatarStack(
  List<AttendeePreview> merged,
) {
  final List<AttendeePreview> joiners = <AttendeePreview>[];
  final List<AttendeePreview> organizers = <AttendeePreview>[];
  for (final AttendeePreview p in merged) {
    if (p.isOrganizer) {
      organizers.add(p);
    } else {
      joiners.add(p);
    }
  }
  joiners.sort(
    (AttendeePreview a, AttendeePreview b) =>
        a.joinedOrder.compareTo(b.joinedOrder),
  );
  organizers.sort(
    (AttendeePreview a, AttendeePreview b) =>
        a.joinedOrder.compareTo(b.joinedOrder),
  );
  return <AttendeePreview>[...joiners, ...organizers];
}

enum AttendeeSort { recent, alphabetical, checkedInFirst }

class AttendeePreview {
  const AttendeePreview({
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.isOrganizer,
    required this.isCurrentUser,
    required this.joinedOrder,
    this.isCheckedIn = false,
  });

  final String userId;
  final String name;
  final String? avatarUrl;
  final bool isOrganizer;
  final bool isCurrentUser;
  final int joinedOrder;
  final bool isCheckedIn;

  AttendeePreview copyWith({bool? isCheckedIn}) {
    return AttendeePreview(
      userId: userId,
      name: name,
      avatarUrl: avatarUrl,
      isOrganizer: isOrganizer,
      isCurrentUser: isCurrentUser,
      joinedOrder: joinedOrder,
      isCheckedIn: isCheckedIn ?? this.isCheckedIn,
    );
  }
}

class AttendeeListSheet extends StatefulWidget {
  const AttendeeListSheet({
    super.key,
    required this.attendees,
    required this.joinedCount,
  });

  final List<AttendeePreview> attendees;
  final int joinedCount;

  @override
  State<AttendeeListSheet> createState() => _AttendeeListSheetState();
}

class _AttendeeListSheetState extends State<AttendeeListSheet> {
  final TextEditingController _searchController = TextEditingController();
  AttendeeSort _sort = AttendeeSort.recent;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AttendeePreview> get _visibleAttendees {
    final String query = _query.trim().toLowerCase();
    final List<AttendeePreview> filtered = widget.attendees
        .where((a) {
          if (query.isEmpty) {
            return true;
          }
          return a.name.toLowerCase().contains(query);
        })
        .toList(growable: false);

    filtered.sort((AttendeePreview a, AttendeePreview b) {
      switch (_sort) {
        case AttendeeSort.recent:
          return a.joinedOrder.compareTo(b.joinedOrder);
        case AttendeeSort.alphabetical:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case AttendeeSort.checkedInFirst:
          if (a.isCheckedIn != b.isCheckedIn) {
            return a.isCheckedIn ? -1 : 1;
          }
          return a.joinedOrder.compareTo(b.joinedOrder);
      }
    });
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final List<AttendeePreview> visible = _visibleAttendees;
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          CupertinoSearchTextField(
            controller: _searchController,
            placeholder: context.l10n.eventsParticipantsSearchPlaceholder,
            onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            onChanged: (String value) {
              setState(() {
                _query = value;
              });
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          CupertinoSlidingSegmentedControl<AttendeeSort>(
            groupValue: _sort,
            thumbColor: AppColors.white,
            backgroundColor: AppColors.inputFill,
            children: <AttendeeSort, Widget>{
              AttendeeSort.recent: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.radius10,
                  vertical: AppSpacing.xs,
                ),
                child: Text(context.l10n.eventsParticipantsRecent),
              ),
              AttendeeSort.alphabetical: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.radius10,
                  vertical: AppSpacing.xs,
                ),
                child: Text(context.l10n.eventsParticipantsAz),
              ),
              AttendeeSort.checkedInFirst: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.radius10,
                  vertical: AppSpacing.xs,
                ),
                child: Text(context.l10n.eventsParticipantsCheckedIn),
              ),
            },
            onValueChanged: (AttendeeSort? value) {
              if (value == null) {
                return;
              }
              setState(() {
                _sort = value;
              });
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: visible.isEmpty
                ? Center(
                    child: Text(
                      context.l10n.eventsParticipantsNoSearchResults,
                      style: AppTypography.eventsBodyMuted(
                        Theme.of(context).textTheme,
                      ),
                    ),
                  )
                : ListView.builder(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.only(
                      bottom:
                          AppSpacing.lg +
                          keyboardInset +
                          AppSheetScrollInsets.of(context),
                    ),
                    itemCount: visible.length,
                    itemBuilder: (BuildContext context, int index) {
                      return AttendeeRow(
                        attendee: visible[index],
                        index: index,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class AttendeeRow extends StatelessWidget {
  const AttendeeRow({super.key, required this.attendee, required this.index});

  final AttendeePreview attendee;
  final int index;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: <Widget>[
          UserAvatarCircle(
            displayName: attendee.name,
            imageUrl: attendee.avatarUrl,
            size: AppSpacing.avatarSm,
            seed: attendee.userId.isNotEmpty ? attendee.userId : attendee.name,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  attendee.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.eventsGroupedRowPrimary(textTheme),
                ),
                if (attendee.isOrganizer || attendee.isCurrentUser)
                  Text(
                    attendee.isOrganizer
                        ? (attendee.isCurrentUser
                              ? context.l10n.eventsParticipantsYouOrganizer
                              : context.l10n.eventsParticipantsOrganizer)
                        : context.l10n.eventsParticipantsYou,
                    style: AppTypography.eventsCaptionStrong(
                      textTheme,
                      color: AppColors.primaryDark,
                    ).copyWith(fontWeight: FontWeight.w500),
                  ),
              ],
            ),
          ),
          if (attendee.isCheckedIn)
            const Icon(
              CupertinoIcons.checkmark_circle_fill,
              size: 18,
              color: AppColors.primaryDark,
            ),
        ],
      ),
    );
  }
}
