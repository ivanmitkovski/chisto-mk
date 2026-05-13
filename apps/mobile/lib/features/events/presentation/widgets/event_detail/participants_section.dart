import 'dart:async';
import 'dart:math' show max, min;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/l10n/app_error_localizations.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/data/events_repository_registry.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/event_detail_surface_decoration.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/events_modal_sheet.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/domain/models/event_participant_row.dart';
import 'package:chisto_mobile/features/events/domain/repositories/events_repository.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/shared/current_user.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/user_avatar_circle.dart';

/// Peek row state for [ParticipantsSection] (keeps data loading out of the widget build tree).
class ParticipantsPeekViewModel extends ChangeNotifier {
  ParticipantsPeekViewModel({required EventsRepository repository}) : _repository = repository;

  final EventsRepository _repository;

  bool peekLoading = true;
  bool peekFailed = false;
  List<AttendeePreview> peekPreviews = <AttendeePreview>[];

  Future<void> loadPeek({
    required EcoEvent event,
    required String youLabel,
  }) async {
    peekLoading = true;
    peekFailed = false;
    notifyListeners();
    try {
      final EventParticipantsPage page = await _repository.fetchParticipants(event.id);
      peekPreviews = mergeParticipantPreviews(
        event: event,
        apiRows: page.items,
        youLabel: youLabel,
      );
      peekLoading = false;
      peekFailed = false;
      notifyListeners();
    } on Object catch (_) {
      peekLoading = false;
      peekFailed = true;
      peekPreviews = <AttendeePreview>[];
      notifyListeners();
    }
  }
}

class ParticipantsSection extends StatefulWidget {
  const ParticipantsSection({
    super.key,
    required this.event,
    this.repository,
  });

  final EcoEvent event;
  final EventsRepository? repository;

  @override
  State<ParticipantsSection> createState() => _ParticipantsSectionState();
}

class _ParticipantsSectionState extends State<ParticipantsSection> {
  late final ParticipantsPeekViewModel _peekVm;

  EcoEvent get event => widget.event;

  @override
  void initState() {
    super.initState();
    _peekVm = ParticipantsPeekViewModel(
      repository: widget.repository ?? EventsRepositoryRegistry.instance,
    );
    _peekVm.addListener(_onPeekVm);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(
        _peekVm.loadPeek(
          event: event,
          youLabel: context.l10n.eventsParticipantsYou,
        ),
      );
    });
  }

  @override
  void didUpdateWidget(covariant ParticipantsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.event.id != event.id ||
        oldWidget.event.participantCount != event.participantCount) {
      unawaited(
        _peekVm.loadPeek(
          event: event,
          youLabel: context.l10n.eventsParticipantsYou,
        ),
      );
    }
  }

  void _onPeekVm() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _peekVm.removeListener(_onPeekVm);
    _peekVm.dispose();
    super.dispose();
  }

  void _showAttendeeList(BuildContext context) {
    AppHaptics.tap();
    showEventsSurfaceModal<void>(
      context: context,
      builder: (BuildContext ctx) {
        return ReportSheetScaffold(
          title: ctx.l10n.eventsParticipantsTitle,
          subtitle: ctx.l10n.eventsCardParticipantsJoined(
            event.participantCount,
          ),
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
            decoration: EventDetailSurfaceDecoration.detailModule(),
            child: Row(
              children: <Widget>[
                AvatarStack(
                  count: count,
                  event: event,
                  previews: _peekVm.peekFailed ? null : _peekVm.peekPreviews,
                  isLoadingPeek: _peekVm.peekLoading,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        event.isJoined && count > 1
                            ? context.l10n.eventsParticipantsYouAndOthers(
                                count - 1,
                              )
                            : context.l10n.eventsParticipantsVolunteersJoined(
                                count,
                              ),
                        style: AppTypography.eventsGroupedRowPrimary(textTheme),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (event.maxParticipants != null)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: AppSpacing.xxs / 2,
                          ),
                          child: Text(
                            context.l10n.eventsParticipantsSpotsLeft(
                              (event.maxParticipants! - count).clamp(
                                0,
                                1000000,
                              ),
                            ),
                            style: AppTypography.eventsListCardMeta(textTheme),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (event.checkedInCount > 0 &&
                          (event.status == EcoEventStatus.inProgress ||
                              event.status == EcoEventStatus.completed))
                        Padding(
                          padding: const EdgeInsets.only(
                            top: AppSpacing.xxs / 2,
                          ),
                          child: Text(
                            context.l10n.eventsParticipantsCheckedInCount(
                              event.checkedInCount,
                              count,
                            ),
                            style: AppTypography.eventsCaptionStrong(
                              textTheme,
                              color: AppColors.primaryDark,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
  State<ParticipantRosterSheetBody> createState() =>
      _ParticipantRosterSheetBodyState();
}

class _ParticipantRosterSheetBodyState
    extends State<ParticipantRosterSheetBody> {
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
        final EventParticipantsPage p = await repo.fetchParticipants(
          widget.event.id,
          cursor: cursor,
        );
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
              style: AppTypography.eventsBodyMuted(Theme.of(context).textTheme),
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
  final String orgName = event.organizerName.trim().isEmpty
      ? '—'
      : event.organizerName;
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
    if (row.userId.isNotEmpty && row.userId == event.organizerId) {
      continue;
    }
    final bool isYou = row.userId.isNotEmpty && row.userId == CurrentUser.id;
    final String name = isYou
        ? youLabel
        : (row.displayName.trim().isEmpty ? '—' : row.displayName);
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
                      style: AppTypography.eventsBodyMuted(
                        Theme.of(context).textTheme,
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
  const AttendeeRow({super.key, required this.attendee, required this.index});

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

/// Overlapping avatar circles: uses [previews] from a light [fetchParticipants] peek
/// when available; falls back to organizer + letter placeholders if [previews] is null.
class AvatarStack extends StatelessWidget {
  const AvatarStack({
    super.key,
    required this.count,
    required this.event,
    this.previews,
    this.isLoadingPeek = false,
  });

  final int count;
  final EcoEvent event;
  final List<AttendeePreview>? previews;
  final bool isLoadingPeek;

  static const double _size = 30;
  static const double _overlap = 9;
  static const double _borderW = 2;

  double _outer() => _size + 2 * _borderW;

  double _totalWidthForSlots(int slotCount) {
    if (slotCount <= 0) {
      return 0;
    }
    final double outer = _outer();
    return outer + (slotCount - 1) * (_size - _overlap);
  }

  Widget _ringedAvatar({required double left, required Widget child}) {
    final double outer = _outer();
    return Positioned(
      left: left,
      child: Container(
        width: outer,
        height: outer,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.white, width: _borderW),
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (count <= 0) {
      return const SizedBox.shrink();
    }

    const double size = _size;
    const double overlap = _overlap;
    final double outer = _outer();

    if (isLoadingPeek && (previews == null || previews!.isEmpty)) {
      return SizedBox(
        width: outer + (size - overlap) + 12,
        height: outer,
        child: Row(
          children: <Widget>[
            UserAvatarCircle(
              displayName: event.organizerName,
              imageUrl: event.organizerAvatarUrl,
              size: size,
              seed: event.organizerId,
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      );
    }

    if (previews != null && previews!.isNotEmpty) {
      final List<AttendeePreview> list = orderPreviewsForAvatarStack(previews!);
      final bool useOverflow = count > 3;
      // [participantCount] is joiners only (API); merge always prepends the organizer.
      // Use max(list.length, count) so "1 volunteer" + organizer still gets two face slots.
      // When /participants returns fewer rows than the event count (common), pad with
      // deterministic placeholder avatars so the stack matches the headline.
      final int targetFaceSlots = useOverflow
          ? 3
          : min(max(list.length, count), 4).clamp(1, 4);
      final int takeKnown = useOverflow
          ? min(3, list.length)
          : min(targetFaceSlots, list.length);
      final List<AttendeePreview> slice = list
          .take(takeKnown)
          .toList(growable: false);
      final int padSlots = targetFaceSlots - slice.length;
      final int stackSlots = useOverflow ? 4 : targetFaceSlots;
      final double totalWidth = _totalWidthForSlots(stackSlots);

      int ringIndex = 0;
      final List<Widget> stackChildren = <Widget>[];
      for (final AttendeePreview p in slice) {
        stackChildren.add(
          _ringedAvatar(
            left: ringIndex * (size - overlap),
            child: UserAvatarCircle(
              displayName: p.name,
              imageUrl: p.avatarUrl,
              size: size,
              seed: p.userId.isNotEmpty ? p.userId : p.name,
            ),
          ),
        );
        ringIndex++;
      }
      for (int p = 0; p < padSlots; p++) {
        final String label = String.fromCharCode(65 + p + ringIndex);
        stackChildren.add(
          _ringedAvatar(
            left: ringIndex * (size - overlap),
            child: UserAvatarCircle(
              displayName: label,
              size: size,
              seed: '${event.id}_peek_pad_${ringIndex}_$p',
            ),
          ),
        );
        ringIndex++;
      }
      if (useOverflow) {
        stackChildren.add(
          _ringedAvatar(
            left: 3 * (size - overlap),
            child: Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.inputFill,
              ),
              child: Text(
                '+${count - 3}',
                style: AppTypography.eventsCaptionStrong(
                  Theme.of(context).textTheme,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        );
      }

      return SizedBox(
        width: totalWidth,
        height: outer,
        child: Stack(clipBehavior: Clip.none, children: stackChildren),
      );
    }

    // Fallback: no peek data (offline / error) — organizer + decorative placeholders.
    final int display = count.clamp(1, 4);
    final double totalWidth = _totalWidthForSlots(display);
    return SizedBox(
      width: totalWidth,
      height: outer,
      child: Stack(
        clipBehavior: Clip.none,
        children: List<Widget>.generate(display, (int i) {
          final double left = i * (size - overlap).toDouble();
          if (i == 0) {
            return _ringedAvatar(
              left: left,
              child: UserAvatarCircle(
                displayName: event.organizerName,
                imageUrl: event.organizerAvatarUrl,
                size: size,
                seed: event.organizerId,
              ),
            );
          }
          final String placeholderLabel = String.fromCharCode(0x40 + i);
          return _ringedAvatar(
            left: left,
            child: UserAvatarCircle(
              displayName: placeholderLabel,
              size: size,
              seed: '${event.id}_stack_$i',
            ),
          );
        }),
      ),
    );
  }
}
