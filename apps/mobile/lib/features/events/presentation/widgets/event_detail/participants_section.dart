import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

class ParticipantsSection extends StatelessWidget {
  const ParticipantsSection({super.key, required this.event});

  final EcoEvent event;

  void _showAttendeeList(BuildContext context) {
    AppHaptics.tap();
    final List<AttendeePreview> attendees = _buildAttendeePreview(event);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.panelBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (BuildContext ctx) {
        return AttendeeListSheet(
          attendees: attendees,
          joinedCount: event.participantCount,
        );
      },
    );
  }

  static List<AttendeePreview> _buildAttendeePreview(EcoEvent event) {
    const List<String> pool = <String>[
      'Ana M.', 'Marko T.', 'Jana K.', 'Stefan P.',
      'Elena R.', 'Nikola D.', 'Petra S.', 'Boris V.',
      'Ivana L.', 'Dejan N.', 'Maja G.', 'Filip B.',
    ];
    final List<AttendeePreview> attendees = <AttendeePreview>[];
    int slotsLeft = event.participantCount.clamp(0, 1000000);
    int seed = 0;

    void addAttendee({
      required String name,
      required bool isOrganizer,
      required bool isCurrentUser,
    }) {
      if (slotsLeft <= 0) {
        return;
      }
      attendees.add(
        AttendeePreview(
          name: name,
          isOrganizer: isOrganizer,
          isCurrentUser: isCurrentUser,
          joinedOrder: seed++,
        ),
      );
      slotsLeft -= 1;
    }

    addAttendee(
      name: event.organizerName,
      isOrganizer: true,
      isCurrentUser: event.isOrganizer,
    );
    if (event.isJoined && !event.isOrganizer) {
      addAttendee(name: 'You', isOrganizer: false, isCurrentUser: true);
    }
    for (final String name in pool) {
      if (slotsLeft <= 0) {
        break;
      }
      addAttendee(name: name, isOrganizer: false, isCurrentUser: false);
    }

    int checkedInSlots = event.checkedInCount.clamp(0, attendees.length);
    if (event.isCheckedIn) {
      checkedInSlots = checkedInSlots.clamp(1, attendees.length);
    }
    final List<AttendeePreview> withStatus = <AttendeePreview>[];
    for (int i = 0; i < attendees.length; i++) {
      final AttendeePreview attendee = attendees[i];
      final bool checkedIn = attendee.isCurrentUser
          ? event.isCheckedIn
          : i < checkedInSlots;
      withStatus.add(attendee.copyWith(isCheckedIn: checkedIn));
    }
    return withStatus;
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final int count = event.participantCount;

    return Semantics(
      button: true,
      label: 'View $count attendees',
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: count > 0 ? () => _showAttendeeList(context) : null,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.panelBackground,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                AvatarStack(count: count),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        event.isJoined && count > 1
                            ? 'You and ${count - 1} other${count == 2 ? '' : 's'} joined'
                            : '$count volunteer${count == 1 ? '' : 's'} joined',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (event.maxParticipants != null)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xxs / 2),
                          child: Text(
                            '${(event.maxParticipants! - count).clamp(0, 1000000)} spots left',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      if (event.checkedInCount > 0 &&
                          (event.status == EcoEventStatus.inProgress ||
                              event.status == EcoEventStatus.completed))
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xxs / 2),
                          child: Text(
                            '${event.checkedInCount} of $count checked in',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.primaryDark,
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (count > 0)
                  Icon(
                    CupertinoIcons.chevron_right,
                    size: 16,
                    color: AppColors.textMuted.withValues(alpha: 0.6),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum AttendeeSort {
  recent,
  alphabetical,
  checkedInFirst,
}

class AttendeePreview {
  const AttendeePreview({
    required this.name,
    required this.isOrganizer,
    required this.isCurrentUser,
    required this.joinedOrder,
    this.isCheckedIn = false,
  });

  final String name;
  final bool isOrganizer;
  final bool isCurrentUser;
  final int joinedOrder;
  final bool isCheckedIn;

  AttendeePreview copyWith({
    bool? isCheckedIn,
  }) {
    return AttendeePreview(
      name: name,
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
    final List<AttendeePreview> filtered = widget.attendees.where((a) {
      if (query.isEmpty) {
        return true;
      }
      return a.name.toLowerCase().contains(query);
    }).toList(growable: false);

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
    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
        child: Column(
          children: <Widget>[
            const SizedBox(height: AppSpacing.xs),
            Container(
              width: AppSpacing.sheetHandle,
              height: AppSpacing.sheetHandleHeight,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xs,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Attendees',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  Text(
                    '${widget.joinedCount} joined',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: CupertinoSearchTextField(
                controller: _searchController,
                placeholder: 'Search attendee',
                onChanged: (String value) {
                  setState(() {
                    _query = value;
                  });
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: CupertinoSlidingSegmentedControl<AttendeeSort>(
                groupValue: _sort,
                thumbColor: AppColors.white,
                backgroundColor: AppColors.inputFill,
                children: <AttendeeSort, Widget>{
                  AttendeeSort.recent: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.radius10, vertical: AppSpacing.xs),
                    child: Text(context.l10n.eventsParticipantsRecent),
                  ),
                  AttendeeSort.alphabetical: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.radius10, vertical: AppSpacing.xs),
                    child: Text(context.l10n.eventsParticipantsAz),
                  ),
                  AttendeeSort.checkedInFirst: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.radius10, vertical: AppSpacing.xs),
                    child: Text(context.l10n.eventsParticipantsCheckedIn),
                  ),
                },
                onValueChanged: (AttendeeSort? value) {
                  if (value == null) {
                    return;
                  }
                  AppHaptics.light();
                  setState(() {
                    _sort = value;
                  });
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: visible.isEmpty
                  ? Center(
                      child: Text(
                        'No attendee matches your search.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textMuted,
                            ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
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
      ),
    );
  }
}

class AttendeeRow extends StatelessWidget {
  const AttendeeRow({
    super.key,
    required this.attendee,
    required this.index,
  });

  final AttendeePreview attendee;
  final int index;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: AppSpacing.avatarSm,
            height: AppSpacing.avatarSm,
            decoration: BoxDecoration(
              color: AppColors.avatarPalette[index % AppColors.avatarPalette.length],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                attendee.name.isNotEmpty ? attendee.name[0].toUpperCase() : '?',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ),
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
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (attendee.isOrganizer || attendee.isCurrentUser)
                  Text(
                    attendee.isOrganizer
                        ? (attendee.isCurrentUser ? 'You · Organizer' : 'Organizer')
                        : 'You',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.primaryDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
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

class AvatarStack extends StatelessWidget {
  const AvatarStack({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final int display = count.clamp(0, 4);
    const double size = 32;
    const double overlap = 10;
    final double totalWidth = size + (display - 1) * (size - overlap);

    return SizedBox(
      width: totalWidth,
      height: size,
      child: Stack(
        children: List<Widget>.generate(display, (int i) {
          return Positioned(
            left: i * (size - overlap),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: AppColors.avatarPalette[i % AppColors.avatarPalette.length].withValues(alpha: 0.3),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.panelBackground, width: 2),
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + i),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
