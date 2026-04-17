import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/data/check_in_repository_registry.dart';
import 'package:chisto_mobile/features/events/data/events_repository_registry.dart';
import 'package:chisto_mobile/features/events/domain/models/check_in_payload.dart';
import 'package:chisto_mobile/features/events/domain/models/event_participant_row.dart';
import 'package:chisto_mobile/features/events/domain/repositories/events_repository.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:chisto_mobile/shared/widgets/primary_button.dart';

/// Bottom sheet: search joined volunteers and pick one for organizer manual check-in.
///
/// Height is **3/4** of the screen (clamped to at least 280px and to the space
/// below the top safe area / parent max). The host sheet uses
/// `isScrollControlled: true` and clears [MediaQuery.viewInsets] so the keyboard
/// does not resize the sheet or move the footer; list + field scroll instead.
/// `useSafeArea: true` on `showModalBottomSheet` keeps layout below the notch.
/// Taps on the sheet dismiss the keyboard (same pattern as `KeyboardAwareFormScroll`).
class ManualCheckInSheet extends StatefulWidget {
  const ManualCheckInSheet({super.key, required this.eventId});

  final String eventId;

  @override
  State<ManualCheckInSheet> createState() => _ManualCheckInSheetState();
}

class _ManualCheckInSheetState extends State<ManualCheckInSheet> {
  static const double _sheetHeightFraction = 0.75;

  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  Object? _error;
  List<EventParticipantRow> _joiners = <EventParticipantRow>[];
  EventParticipantRow? _selected;
  String _query = '';

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Set<String> get _checkedInUserIds {
    final List<CheckedInAttendee> list = CheckInRepositoryRegistry.instance
        .checkedInAttendees(widget.eventId);
    return list
        .map((CheckedInAttendee a) => a.userId)
        .whereType<String>()
        .where((String id) => id.isNotEmpty)
        .toSet();
  }

  List<EventParticipantRow> get _eligibleJoiners {
    final Set<String> checked = _checkedInUserIds;
    return _joiners
        .where((EventParticipantRow r) => !checked.contains(r.userId))
        .toList(growable: false);
  }

  List<EventParticipantRow> get _visibleRows {
    final String q = _query.trim().toLowerCase();
    final List<EventParticipantRow> base = _eligibleJoiners;
    if (q.isEmpty) {
      return base;
    }
    return base
        .where(
          (EventParticipantRow r) =>
              r.displayName.toLowerCase().contains(q) ||
              r.userId.toLowerCase().contains(q),
        )
        .toList(growable: false);
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
          widget.eventId,
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
      setState(() {
        _joiners = rows;
        _loading = false;
        _error = null;
        _selected = null;
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

  String _errorMessage(BuildContext context) {
    final Object? e = _error;
    if (e is AppError && e.message.isNotEmpty) {
      return e.message;
    }
    return context.l10n.eventsParticipantsLoadFailed;
  }

  void _onCancel() {
    AppHaptics.tap();
    Navigator.of(context).pop();
  }

  void _onAdd() {
    AppHaptics.tap();
    final EventParticipantRow? pick = _selected;
    if (pick == null) {
      AppSnack.show(
        context,
        message: context.l10n.eventsOrganizerManualCheckInSelectParticipant,
        type: AppSnackType.warning,
      );
      return;
    }
    Navigator.of(context).pop(pick);
  }

  @override
  Widget build(BuildContext context) {
    final double screenH = MediaQuery.sizeOf(context).height;
    final double topSafe = MediaQuery.viewPaddingOf(context).top;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double parentMax = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : screenH;
        final double maxBelowNotch = screenH - topSafe;
        final double maxAllowed =
            math.min(parentMax, maxBelowNotch);
        final double desired = screenH * _sheetHeightFraction;
        final double sheetHeight =
            math.min(maxAllowed, math.max(280.0, desired));

        final TextTheme textTheme = Theme.of(context).textTheme;

        return GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          behavior: HitTestBehavior.translucent,
          child: SizedBox(
            height: sheetHeight,
            child: Material(
              color: AppColors.transparent,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.panelBackground,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppSpacing.radiusCard),
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.06),
                      blurRadius: 36,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppSpacing.radiusCard),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            const SizedBox(height: AppSpacing.xs),
                            const Center(child: _SheetHandle()),
                            const SizedBox(height: AppSpacing.sm),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          context.l10n.eventsManualCheckInTitle,
                                          style: AppTypography.eventsSheetTitle(textTheme),
                                        ),
                                        const SizedBox(height: AppSpacing.xs),
                                        Text(
                                          context
                                              .l10n
                                              .eventsOrganizerManualCheckInSubtitle,
                                          style: AppTypography.eventsSupportingCaption(
                                            textTheme,
                                          ).copyWith(height: 1.35),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ReportCircleIconButton(
                                    icon: CupertinoIcons.xmark,
                                    semanticLabel: context.l10n.commonClose,
                                    onTap: _onCancel,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                              ),
                              child: Divider(
                                color: AppColors.divider.withValues(alpha: 0.6),
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            if (_loading)
                              const Expanded(
                                child: Center(
                                  child: CupertinoActivityIndicator(radius: 16),
                                ),
                              )
                            else if (_error != null)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.lg),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Text(
                                        _errorMessage(context),
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: AppColors.textMuted,
                                            ),
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                      TextButton(
                                        onPressed: () => unawaited(_load()),
                                        child: Text(
                                          context.l10n.eventsParticipantsRetry,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else ...<Widget>[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                ),
                                child: CupertinoSearchTextField(
                                  controller: _searchController,
                                  placeholder: context
                                      .l10n
                                      .eventsParticipantsSearchPlaceholder,
                                  onSubmitted: (_) {
                                    FocusManager.instance.primaryFocus
                                        ?.unfocus();
                                  },
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Expanded(
                                child: _eligibleJoiners.isEmpty
                                    ? Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(
                                            AppSpacing.lg,
                                          ),
                                          child: Text(
                                            context
                                                .l10n
                                                .eventsOrganizerManualCheckInNoJoiners,
                                            textAlign: TextAlign.center,
                                            style: AppTypography.eventsBodyMuted(textTheme),
                                          ),
                                        ),
                                      )
                                    : _visibleRows.isEmpty
                                    ? Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(
                                            AppSpacing.lg,
                                          ),
                                          child: Text(
                                            context
                                                .l10n
                                                .eventsParticipantsNoSearchResults,
                                            textAlign: TextAlign.center,
                                            style: AppTypography.eventsBodyMuted(textTheme),
                                          ),
                                        ),
                                      )
                                    : ListView.builder(
                                        keyboardDismissBehavior:
                                            ScrollViewKeyboardDismissBehavior
                                                .onDrag,
                                        padding: const EdgeInsets.only(
                                          left: AppSpacing.lg,
                                          right: AppSpacing.lg,
                                          bottom: AppSpacing.md,
                                        ),
                                        itemCount: _visibleRows.length,
                                        itemBuilder: (BuildContext context, int index) {
                                          final EventParticipantRow row =
                                              _visibleRows[index];
                                          final bool selected =
                                              _selected?.userId == row.userId;
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: AppSpacing.xs,
                                            ),
                                            child: Material(
                                              color: AppColors.transparent,
                                              child: InkWell(
                                                onTap: () {
                                                  AppHaptics.tap();
                                                  setState(() {
                                                    _selected = row;
                                                  });
                                                },
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      AppSpacing.radiusMd,
                                                    ),
                                                child: Ink(
                                                  decoration: BoxDecoration(
                                                    color: selected
                                                        ? AppColors.primary
                                                              .withValues(
                                                                alpha: 0.1,
                                                              )
                                                        : AppColors.inputFill,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          AppSpacing.radiusMd,
                                                        ),
                                                    border: Border.all(
                                                      color: selected
                                                          ? AppColors
                                                                .primaryDark
                                                          : AppColors.divider
                                                                .withValues(
                                                                  alpha: 0.7,
                                                                ),
                                                      width: selected ? 1.5 : 1,
                                                    ),
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          AppSpacing.md,
                                                        ),
                                                    child: Row(
                                                      children: <Widget>[
                                                        Expanded(
                                                          child: Text(
                                                            row.displayName,
                                                            maxLines: 2,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: AppTypography
                                                                .eventsFormLeadHeading(
                                                              textTheme,
                                                            ),
                                                          ),
                                                        ),
                                                        if (selected)
                                                          Icon(
                                                            CupertinoIcons
                                                                .checkmark_circle_fill,
                                                            color: AppColors
                                                                .primaryDark,
                                                            size: 22,
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      DecoratedBox(
                        decoration: const BoxDecoration(
                          color: AppColors.panelBackground,
                          border: Border(
                            top: BorderSide(
                              color: AppColors.divider,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.md,
                            AppSpacing.lg,
                            AppSpacing.lg +
                                MediaQuery.paddingOf(context).bottom,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: OutlinedButton(
                                  onPressed: _onCancel,
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: AppColors.divider,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusPill,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    context.l10n.commonCancel,
                                    style: AppTypography.eventsSecondaryCtaLabel(
                                      textTheme,
                                    ).copyWith(color: AppColors.primaryDark),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              PrimaryButton(
                                label: context.l10n.eventsManualCheckInAdd,
                                enabled:
                                    !_loading &&
                                    _error == null &&
                                    _selected != null,
                                onPressed: _onAdd,
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
        );
      },
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSpacing.sheetHandle,
      height: AppSpacing.sheetHandleHeight,
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
      ),
    );
  }
}
