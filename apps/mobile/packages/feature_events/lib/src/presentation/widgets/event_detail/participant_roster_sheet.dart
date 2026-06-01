import 'dart:async';

import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/l10n/app_error_localizations.dart';
import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/shared/current_user.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_events/src/application/events_providers.dart';
import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:feature_events/src/domain/models/event_participant_row.dart';
import 'package:feature_events/src/domain/repositories/events_repository.dart';
import 'package:feature_events/src/presentation/widgets/event_detail/attendee_list_sheet.dart';
import 'package:flutter/material.dart';

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
      final EventsRepository repo = readEventsRepository();
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
        child: Center(child: AppLoadingIndicator()),
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
            AppButton.text(
              label: context.l10n.eventsParticipantsRetry,
              onPressed: () => unawaited(_load()),
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
