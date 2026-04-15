import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/l10n/app_error_localizations.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/data/events_repository_registry.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/domain/models/event_participant_row.dart';
import 'package:chisto_mobile/features/events/domain/repositories/events_repository.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/shared/current_user.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/user_avatar_circle.dart';

class ParticipantsSection extends StatelessWidget {
  const ParticipantsSection({super.key, required this.event});

  final EcoEvent event;

  void _showAttendeeList(BuildContext context) {
    AppHaptics.tap();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.transparent,
      isScrollControlled: true,
      builder: (BuildContext ctx) {
        return ReportSheetScaffold(
          title: ctx.l10n.eventsParticipantsTitle,
          subtitle: ctx.l10n.eventsCardParticipantsJoined(event.participantCount),
          maxHeightFactor: 0.84,
          child: ParticipantRosterSheetBody(event: event),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final int count = event.participantCount;

    return Semantics(
      button: true,
      label: count > 0
          ? context.l10n.eventsParticipantsViewSemantic(count)
          : context.l10n.eventsParticipantsViewRosterSemantic,
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: () => _showAttendeeList(context),
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
                AvatarStack(count: count, event: event),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        event.isJoined && count > 1
                            ? context.l10n.eventsParticipantsYouAndOthers(count - 1)
                            : context.l10n.eventsParticipantsVolunteersJoined(count),
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (event.maxParticipants != null)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xxs / 2),
                          child: Text(
                            context.l10n.eventsParticipantsSpotsLeft(
                              (event.maxParticipants! - count).clamp(0, 1000000),
                            ),
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      if (event.checkedInCount > 0 &&
                          (event.status == EcoEventStatus.inProgress ||
                              event.status == EcoEventStatus.completed))
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xxs / 2),
                          child: Text(
                            context.l10n.eventsParticipantsCheckedInCount(
                              event.checkedInCount,
                              count,
                            ),
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
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

/// Loads joiners from [EventsRepository.fetchParticipants] and prepends the organizer from [EcoEvent].
class ParticipantRosterSheetBody extends StatefulWidget {
  const ParticipantRosterSheetBody({super.key, required this.event});

  final EcoEvent event;

  @override
  State<ParticipantRosterSheetBody> createState() => _ParticipantRosterSheetBodyState();
}

class _ParticipantRosterSheetBodyState extends State<ParticipantRosterSheetBody> {
  bool _loading = true;
  Object? _error;
  List<AttendeePreview> _attendees = <AttendeePreview>[];

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final EventsRepository repo = EventsRepositoryRegistry.instance;
      final List<EventParticipantRow> rows = <EventParticipantRow>[];
      String? cursor;
      for (int page = 0; page < 50; page++) {
        final EventParticipantsPage p =
            await repo.fetchParticipants(widget.event.id, cursor: cursor);
        rows.addAll(p.items);
        if (!p.hasMore) {
          break;
        }
        final String? next = p.nextCursor;
        if (next == null || next.isEmpty) {
          break;
        }
        cursor = next;
      }
      if (!mounted) {
        return;
      }
      final String youLabel = context.l10n.eventsParticipantsYou;
      setState(() {
        _attendees = mergeParticipantPreviews(
          event: widget.event,
          apiRows: rows,
          youLabel: youLabel,
        );
        _loading = false;
        _error = null;
      });
    } on Object catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  String _errorMessage() {
    final Object? e = _error;
    if (e is AppError) {
      return localizedAppErrorMessage(context.l10n, e);
    }
    return context.l10n.eventsParticipantsLoadFailed;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              _errorMessage(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: () => unawaited(_load()),
              child: Text(context.l10n.eventsParticipantsRetry),
            ),
          ],
        ),
      );
    }
    return AttendeeListSheet(
      attendees: _attendees,
      joinedCount: widget.event.participantCount,
    );
  }
}

List<AttendeePreview> mergeParticipantPreviews({
  required EcoEvent event,
  required List<EventParticipantRow> apiRows,
  required String youLabel,
}) {
  int order = 0;
  final List<AttendeePreview> list = <AttendeePreview>[];
  final String orgName =
      event.organizerName.trim().isEmpty ? '—' : event.organizerName;
  list.add(
    AttendeePreview(
      userId: event.organizerId,
      name: orgName,
      avatarUrl: event.organizerAvatarUrl,
      isOrganizer: true,
      isCurrentUser: event.isOrganizer,
      joinedOrder: order++,
      isCheckedIn: event.isOrganizer && event.isCheckedIn,
    ),
  );
  for (final EventParticipantRow row in apiRows) {
    final bool isYou = row.userId.isNotEmpty && row.userId == CurrentUser.id;
    final String name =
        isYou ? youLabel : (row.displayName.trim().isEmpty ? '—' : row.displayName);
    list.add(
      AttendeePreview(
        userId: row.userId,
        name: name,
        avatarUrl: row.avatarUrl,
        isOrganizer: false,
        isCurrentUser: isYou,
        joinedOrder: order++,
        isCheckedIn: isYou && event.isCheckedIn,
      ),
    );
  }
  return list;
}

enum AttendeeSort {
  recent,
  alphabetical,
  checkedInFirst,
}

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

  AttendeePreview copyWith({
    bool? isCheckedIn,
  }) {
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
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.62,
      child: Column(
        children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: CupertinoSearchTextField(
                controller: _searchController,
                placeholder: context.l10n.eventsParticipantsSearchPlaceholder,
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
                        context.l10n.eventsParticipantsNoSearchResults,
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
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (attendee.isOrganizer || attendee.isCurrentUser)
                  Text(
                    attendee.isOrganizer
                        ? (attendee.isCurrentUser
                            ? context.l10n.eventsParticipantsYouOrganizer
                            : context.l10n.eventsParticipantsOrganizer)
                        : context.l10n.eventsParticipantsYou,
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

/// Decorative overlapping avatar circles (up to 4). First slot is the organizer
/// (photo or initials). Extra slots use placeholder initials — we do not load the
/// full participant list until the user opens the roster.
class AvatarStack extends StatelessWidget {
  const AvatarStack({super.key, required this.count, required this.event});

  final int count;
  final EcoEvent event;

  @override
  Widget build(BuildContext context) {
    final int display = count.clamp(0, 4);
    if (display == 0) {
      return const SizedBox.shrink();
    }
    const double size = 30;
    const double overlap = 9;
    const double borderW = 2;
    // Border is inset: a 30px avatar needs a 34px box so the child is not overflow-clipped.
    final double outer = size + 2 * borderW;
    final double totalWidth = outer + (display - 1) * (size - overlap);

    return SizedBox(
      width: totalWidth,
      height: outer,
      child: Stack(
        clipBehavior: Clip.none,
        children: List<Widget>.generate(display, (int i) {
          final double left = i * (size - overlap).toDouble();
          if (i == 0) {
            return Positioned(
              left: left,
              child: Container(
                width: outer,
                height: outer,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.panelBackground, width: borderW),
                ),
                child: UserAvatarCircle(
                  displayName: event.organizerName,
                  imageUrl: event.organizerAvatarUrl,
                  size: size,
                  seed: event.organizerId,
                ),
              ),
            );
          }
          // Placeholder letters until roster is opened (no per-user data on the event).
          final String placeholderLabel = String.fromCharCode(0x40 + i);
          return Positioned(
            left: left,
            child: Container(
              width: outer,
              height: outer,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.panelBackground, width: borderW),
              ),
              child: UserAvatarCircle(
                displayName: placeholderLabel,
                size: size,
                seed: '${event.id}_stack_$i',
              ),
            ),
          );
        }),
      ),
    );
  }
}
