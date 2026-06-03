library;

import 'dart:async';

import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/l10n/app_error_localizations.dart';
import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/core/navigation/app_navigation.dart';
import 'package:chisto_infrastructure/core/navigation/app_routes.dart';
import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:chisto_infrastructure/core/providers/events_providers.dart';
import 'package:chisto_infrastructure/shared/current_user.dart';
import 'package:chisto_infrastructure/shared/utils/app_haptics.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_back_button.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_snack.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_events/src/application/schedule_conflict_preview_controller.dart';
import 'package:feature_events/src/data/event_site_resolver.dart';
import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:feature_events/src/presentation/event_ui_mappers.dart';
import 'package:feature_events/src/presentation/navigation/organizer_certification_navigation.dart';
import 'package:feature_events/src/presentation/screens/organizer_toolkit/organizer_toolkit_screen.dart';
import 'package:feature_events/src/presentation/utils/create_event_form_snapshot.dart';
import 'package:feature_events/src/presentation/utils/create_event_form_validation.dart';
import 'package:feature_events/src/presentation/utils/event_schedule_constraints.dart';
import 'package:feature_events/src/presentation/utils/events_localized_strings.dart';
import 'package:feature_events/src/presentation/widgets/create_event/create_event_async_site_picker.dart';
import 'package:feature_events/src/presentation/widgets/create_event/create_event_details_section.dart';
import 'package:feature_events/src/presentation/widgets/create_event/create_event_help_sheet.dart';
import 'package:feature_events/src/presentation/widgets/create_event/create_event_schedule_section.dart';
import 'package:feature_events/src/presentation/widgets/create_event/create_event_screen_skeleton.dart';
import 'package:feature_events/src/presentation/widgets/create_event/create_event_site_section.dart';
import 'package:feature_events/src/presentation/widgets/create_event/create_event_step_progress_header.dart';
import 'package:feature_events/src/presentation/widgets/create_event/create_event_sticky_footer.dart';
import 'package:feature_events/src/presentation/widgets/create_event/create_event_volunteer_cap_picker_sheet.dart';
import 'package:feature_events/src/presentation/widgets/event_form/event_form_gear_sheet_footer.dart';
import 'package:feature_events/src/presentation/widgets/event_success_dialog.dart';
import 'package:feature_events/src/presentation/widgets/events_modal_sheet.dart';
import 'package:feature_home/feature_home.dart';
import 'package:feature_profile/feature_profile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

part 'create_event_sheet_build.dart';
part 'create_event_sheet_pickers.dart';

class CreateEventSheet extends ConsumerStatefulWidget {
  const CreateEventSheet({
    super.key,
    this.preselectedSiteId,
    this.preselectedSiteName,
    this.preselectedSiteImageUrl,
    this.preselectedSiteDistanceKm,
    this.clock,
  });

  final String? preselectedSiteId;
  final String? preselectedSiteName;
  final String? preselectedSiteImageUrl;
  final double? preselectedSiteDistanceKm;

  /// When null, uses wall clock. Widget tests should supply a fixed instant so
  /// schedule validation and step progress do not depend on CI time-of-day.
  @visibleForTesting
  final DateTime Function()? clock;

  @override
  ConsumerState<CreateEventSheet> createState() => _CreateEventSheetState();
}

class _CreateEventSheetState extends ConsumerState<CreateEventSheet>
    with SingleTickerProviderStateMixin {
  EventSiteSummary? _selectedSite;
  DateTime? _selectedDate;
  EventTime _startTime = const EventTime(hour: 12, minute: 0);
  EventTime _endTime = const EventTime(hour: 14, minute: 0);
  EcoEventCategory? _selectedCategory;
  final Set<EventGear> _selectedGear = <EventGear>{};
  CleanupScale? _selectedScale;
  EventDifficulty? _selectedDifficulty;
  int? _maxParticipants;
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  bool _showValidationErrors = false;
  bool _submitting = false;
  bool _showBootstrapSkeleton = true;
  bool _appliedLocalizedCoercedSiteDescription = false;

  static const int _minBootstrapVisibleMs = 360;

  late final CreateEventFormSnapshot _initialSnapshot;
  late final AnimationController _sectionEntranceController;

  final GlobalKey _siteSectionKey = GlobalKey();
  final GlobalKey _scheduleSectionKey = GlobalKey();
  final GlobalKey _titleFieldKey = GlobalKey();
  final GlobalKey _categorySectionKey = GlobalKey();

  late final ScheduleConflictPreviewController _scheduleConflict;
  int _localSyntheticEventNonce = 0;

  DateTime _now() => widget.clock?.call() ?? DateTime.now();

  bool get _isTimeRangeValid {
    final DateTime? d = _selectedDate;
    if (d == null) {
      return false;
    }
    final DateTime si = eventScheduleInstantLocal(
      DateUtils.dateOnly(d),
      _startTime,
    );
    final DateTime ei = eventScheduleInstantLocal(
      DateUtils.dateOnly(d),
      _endTime,
    );
    return ei.isAfter(si);
  }

  ScheduleValidationIssue? _createScheduleIssue() {
    final DateTime? d = _selectedDate;
    if (d == null) {
      return null;
    }
    return validateCreateOrUpcomingEditSchedule(
      dateOnly: DateUtils.dateOnly(d),
      start: _startTime,
      end: _endTime,
      now: _now(),
    );
  }

  bool get _isScheduleValid => _createScheduleIssue() == null;

  ({DateTime? minStart, DateTime? minEnd}) _schedulePickerBounds() {
    final DateTime? d = _selectedDate;
    if (d == null) {
      return (minStart: null, minEnd: null);
    }
    final DateTime startOnly = DateUtils.dateOnly(d);
    final DateTime now = _now();
    return (
      minStart: pickerMinimumForStart(dateOnly: startOnly, now: now),
      minEnd: pickerMinimumForEnd(
        dateOnly: startOnly,
        start: _startTime,
        now: now,
        editStatus: null,
      ),
    );
  }

  bool get _isValid => createEventFormIsSubmittable(
    hasSite: _selectedSite != null,
    hasDate: _selectedDate != null,
    category: _selectedCategory,
    titleTrimmed: _titleController.text.trim(),
    timeRangeValid: _isTimeRangeValid,
    scheduleValid: _isScheduleValid,
  );

  bool get _isDirty => !_initialSnapshot.matches(_captureFormFields());

  CreateEventFormFields _captureFormFields() {
    final List<String> gearNames =
        _selectedGear.map((EventGear g) => g.name).toList()..sort();
    return CreateEventFormFields(
      siteId: _selectedSite?.id,
      dateMillis: _selectedDate?.millisecondsSinceEpoch,
      startHour: _startTime.hour,
      startMinute: _startTime.minute,
      endHour: _endTime.hour,
      endMinute: _endTime.minute,
      categoryIndex: _selectedCategory?.index,
      gearNames: gearNames,
      scaleIndex: _selectedScale?.index,
      difficultyIndex: _selectedDifficulty?.index,
      title: _titleController.text,
      description: _descriptionController.text,
      maxParticipants: _maxParticipants,
    );
  }

  @override
  void initState() {
    super.initState();
    _scheduleConflict = ScheduleConflictPreviewController(
      eventsRepository: readEventsRepository(),
      isMounted: () => mounted,
      onChanged: () {
        if (mounted) {
          setState(() {});
        }
      },
    );
    final DateTime now = _now();
    _selectedSite = EventSiteResolver.coerceSummary(
      siteId: widget.preselectedSiteId,
      siteName: widget.preselectedSiteName,
      siteImageUrl: widget.preselectedSiteImageUrl,
      siteDistanceKm: widget.preselectedSiteDistanceKm,
    );
    _selectedDate = DateUtils.dateOnly(now);
    final ({EventTime start, EventTime end}) slot = defaultStartEndForDate(
      dateOnly: _selectedDate!,
      now: now,
    );
    _startTime = slot.start;
    _endTime = slot.end;
    final ({EventTime start, EventTime end}) boot =
        clampCreateOrUpcomingSchedule(
          dateOnly: _selectedDate!,
          start: _startTime,
          end: _endTime,
          now: now,
        );
    _startTime = boot.start;
    _endTime = boot.end;
    _initialSnapshot = CreateEventFormSnapshot(_captureFormFields());
    _sectionEntranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_redirectIfOrganizerNotCertified());
      unawaited(_completeBootstrapSkeleton());
    });
  }

  /// Deep link to [AppRoutes.eventsCreate] bypasses [EventsNavigation.openCreate];
  /// uncertified organizers are sent through the toolkit first.
  Future<void> _redirectIfOrganizerNotCertified() async {
    if (!mounted) {
      return;
    }
    if (!ref.read(appBootstrapProvider).isInitialized) {
      return;
    }
    if (ref.read(authStateProvider).isOrganizerCertified) {
      return;
    }
    await Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(
        settings: const RouteSettings(
          name: organizerCertificationToolkitRouteName,
        ),
        builder: (_) => const OrganizerToolkitScreen(),
      ),
    );
    if (!mounted) {
      return;
    }
    if (!ref.read(authStateProvider).isOrganizerCertified) {
      Navigator.of(context).pop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_appliedLocalizedCoercedSiteDescription) {
      return;
    }
    _appliedLocalizedCoercedSiteDescription = true;
    final EventSiteSummary? localized = EventSiteResolver.coerceSummary(
      siteId: widget.preselectedSiteId,
      siteName: widget.preselectedSiteName,
      siteImageUrl: widget.preselectedSiteImageUrl,
      siteDistanceKm: widget.preselectedSiteDistanceKm,
      syntheticSiteDescription: context.l10n.eventsSiteCoercedDescription,
    );
    if (localized != null) {
      setState(() => _selectedSite = localized);
    }
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scheduleConflictPreviewDebounced(),
    );
  }

  Future<void> _completeBootstrapSkeleton() async {
    await Future<void>.delayed(
      const Duration(milliseconds: _minBootstrapVisibleMs),
    );
    if (!mounted) {
      return;
    }
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    setState(() => _showBootstrapSkeleton = false);
    if (!mounted) {
      return;
    }
    if (reduceMotion) {
      _sectionEntranceController.value = 1;
    } else {
      unawaited(_sectionEntranceController.forward(from: 0));
    }
    _scheduleConflictPreviewDebounced();
  }

  /// Progress milestones match [_isValid].
  int get _completedSteps => createEventFormCompletedSteps(
    hasSite: _selectedSite != null,
    hasDate: _selectedDate != null,
    category: _selectedCategory,
    titleTrimmed: _titleController.text.trim(),
    timeRangeValid: _isTimeRangeValid,
    scheduleValid: _isScheduleValid,
  );

  @override
  void dispose() {
    _scheduleConflict.dispose();
    _sectionEntranceController.dispose();
    _descriptionController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _scheduleConflictPreviewDebounced() {
    final EventSiteSummary? site = _selectedSite;
    final DateTime? date = _selectedDate;
    if (site == null || date == null) {
      _scheduleConflict.schedulePreview(
        scheduleValid: false,
        siteId: '',
        startLocal: DateTime.now(),
        endLocal: DateTime.now(),
        clearOnInvalid: true,
      );
      return;
    }
    _scheduleConflict.schedulePreview(
      scheduleValid: _isScheduleValid,
      siteId: site.id,
      startLocal: eventScheduleInstantLocal(
        DateUtils.dateOnly(date),
        _startTime,
      ),
      endLocal: eventScheduleInstantLocal(DateUtils.dateOnly(date), _endTime),
    );
  }

  Widget _sectionGroupCaption(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text.toUpperCase(),
        style: AppTypography.eventsMicroSectionHeading(
          Theme.of(context).textTheme,
        ).copyWith(letterSpacing: 0.7),
      ),
    );
  }

  Widget _staggeredSection({required int slot, required Widget child}) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return child;
    }
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _sectionEntranceController,
        curve: Interval(
          0.05 + slot * 0.2,
          0.55 + slot * 0.2,
          curve: AppMotion.smooth,
        ),
      ),
      child: child,
    );
  }

  Future<bool> _confirmDiscard() async {
    final bool? discard = await showCupertinoDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return CupertinoAlertDialog(
          title: Text(ctx.l10n.createEventDiscardTitle),
          content: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(ctx.l10n.createEventDiscardBody),
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(ctx.l10n.createEventDiscardKeepEditing),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(ctx.l10n.commonDiscard),
            ),
          ],
        );
      },
    );
    return discard ?? false;
  }

  Future<void> _onBackPressed() async {
    if (!_isDirty) {
      unawaited(Navigator.of(context).maybePop());
      return;
    }
    // `maybePop` respects `PopScope(canPop: !_isDirty)` and would re-fire
    // `onPopInvokedWithResult` instead of dismissing.
    final bool discard = await _confirmDiscard();
    if (!mounted) {
      return;
    }
    if (discard) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleCreate() async {
    if (_submitting) {
      return;
    }
    if (!_isValid) {
      AppHaptics.warning();
      setState(() => _showValidationErrors = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _scrollToFirstInvalid();
      });
      return;
    }

    final bool? goAhead = await _scheduleConflict.confirmProceedDespiteConflict(
      context,
    );
    if (goAhead != true || !mounted) {
      return;
    }

    final DateTime now = _now();
    final DateTime selectedDate = _selectedDate ?? DateUtils.dateOnly(now);
    final EventSiteSummary? selectedSite = _selectedSite;
    if (selectedSite == null) {
      AppHaptics.warning();
      setState(() => _showValidationErrors = true);
      return;
    }
    final String eventId =
        'evt-local-${now.microsecondsSinceEpoch}-${_localSyntheticEventNonce++}';
    final String title = _titleController.text.trim();
    final String description = _descriptionController.text.trim().isEmpty
        ? context.l10n.createEventDefaultDescription
        : _descriptionController.text.trim();
    final EcoEventCategory category =
        _selectedCategory ?? EcoEventCategory.generalCleanup;
    final DateTime startDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final EcoEvent createdEvent = EcoEvent(
      id: eventId,
      title: title,
      description: description,
      category: category,
      siteId: selectedSite.id,
      siteName: selectedSite.title,
      siteImageUrl: selectedSite.imageUrl,
      siteDistanceKm: selectedSite.distanceKm,
      organizerId: CurrentUser.id,
      organizerName: CurrentUser.displayName,
      date: startDay,
      endDate: null,
      startTime: _startTime,
      endTime: _endTime,
      participantCount: 0,
      status: EcoEventStatus.upcoming,
      createdAt: now,
      isJoined: false,
      gear: _selectedGear.toList(growable: false),
      scale: _selectedScale,
      difficulty: _selectedDifficulty,
      maxParticipants: _maxParticipants,
      moderationApproved: false,
    );

    setState(() => _submitting = true);
    EcoEvent created;
    try {
      created = await readEventsRepository().create(createdEvent);
    } on AppError catch (e) {
      if (mounted) {
        AppSnack.show(
          context,
          message: localizedAppErrorMessage(context.l10n, e),
          type: AppSnackType.warning,
        );
      }
      if (mounted) {
        setState(() => _submitting = false);
      }
      return;
    } on Object {
      if (mounted) {
        AppSnack.show(
          context,
          message: context.l10n.eventsCreateGenericError,
          type: AppSnackType.warning,
        );
      }
      if (mounted) {
        setState(() => _submitting = false);
      }
      return;
    }

    if (!mounted) {
      return;
    }
    setState(() => _submitting = false);

    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.overlay,
      builder: (BuildContext context) => EventSuccessDialog(
        title: created.title,
        siteName: created.siteName,
        requiresModeration: !created.moderationApproved,
      ),
    );

    if ((confirmed ?? false) && mounted) {
      Navigator.of(context).pop(created);
    }
  }

  Future<(double?, double?)> _tryUserLatLng() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return (null, null);
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return (null, null);
      }
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 8),
      );
      return (position.latitude, position.longitude);
    } on Object {
      return (null, null);
    }
  }

  List<EventSiteSummary> _offlineSiteSummaries() {
    return const <EventSiteSummary>[];
  }

  Future<CreateEventSitesLoadResult> _loadSitesForCreatePicker() async {
    if (!ref.read(appBootstrapProvider).isInitialized) {
      return CreateEventSitesLoadResult(
        sites: _offlineSiteSummaries(),
        usedOfflineFallback: true,
        networkError: false,
      );
    }
    final (double? lat, double? lng) = await _tryUserLatLng();
    try {
      final SitesListResult result = await ref
          .read(sitesRepositoryProvider)
          .getSites(
            latitude: lat,
            longitude: lng,
            radiusKm: 120,
            page: 1,
            limit: 100,
            sort: 'hybrid',
            mode: 'for_you',
          );
      final List<EventSiteSummary> sites = result.sites
          .map(EventSiteSummary.fromPollutionSite)
          .toList(growable: false);
      sites.sort((EventSiteSummary a, EventSiteSummary b) {
        final bool da = a.distanceKm >= 0;
        final bool db = b.distanceKm >= 0;
        if (da && db) {
          final int c = a.distanceKm.compareTo(b.distanceKm);
          if (c != 0) {
            return c;
          }
        } else if (da != db) {
          return da ? -1 : 1;
        }
        return a.title.compareTo(b.title);
      });
      if (sites.isEmpty) {
        return CreateEventSitesLoadResult(
          sites: _offlineSiteSummaries(),
          usedOfflineFallback: true,
          networkError: false,
        );
      }
      return CreateEventSitesLoadResult(sites: sites);
    } on Object {
      return CreateEventSitesLoadResult(
        sites: _offlineSiteSummaries(),
        usedOfflineFallback: true,
        networkError: true,
      );
    }
  }

  void _ensureSectionVisible(GlobalKey key) {
    final BuildContext? ctx = key.currentContext;
    if (ctx == null) {
      return;
    }
    Scrollable.ensureVisible(
      ctx,
      duration: AppMotion.standard,
      curve: AppMotion.standardCurve,
      alignment: 0.12,
    );
  }

  void _scrollToFirstInvalid() {
    if (_selectedSite == null) {
      _ensureSectionVisible(_siteSectionKey);
      return;
    }
    if (_selectedDate == null) {
      _ensureSectionVisible(_scheduleSectionKey);
      return;
    }
    if (!_isTimeRangeValid || !_isScheduleValid) {
      _ensureSectionVisible(_scheduleSectionKey);
      return;
    }
    if (_titleController.text.trim().length < 3) {
      _ensureSectionVisible(_titleFieldKey);
      return;
    }
    if (_selectedCategory == null) {
      _ensureSectionVisible(_categorySectionKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    final int steps = _completedSteps;

    // When canPop is false (dirty form), iOS edge swipe invokes
    // onPopInvokedWithResult(didPop: false) so we can show the discard dialog.
    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          return;
        }
        final bool discard = await _confirmDiscard();
        if (!context.mounted) {
          return;
        }
        if (discard) {
          Navigator.of(context).pop(result);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.appBackground,
        // Keep the form from resizing for the keyboard; the sticky CTA stays
        // pinned to the bottom safe area (not lifted above the keyboard).
        resizeToAvoidBottomInset: false,
        body: Column(
          children: <Widget>[
            _buildAppBar(context, topPadding),
            Expanded(
              child: AnimatedSwitcher(
                duration: AppMotion.medium,
                switchInCurve: AppMotion.smooth,
                switchOutCurve: AppMotion.standardCurve,
                child: _showBootstrapSkeleton
                    ? const Padding(
                        key: ValueKey<String>('create_event_bootstrap'),
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.sm,
                          AppSpacing.lg,
                          0,
                        ),
                        child: CreateEventScreenSkeleton(),
                      )
                    : Padding(
                        key: const ValueKey<String>('create_event_form'),
                        padding: EdgeInsets.zero,
                        child: _buildFormScroll(context, steps),
                      ),
              ),
            ),
            if (_showBootstrapSkeleton)
              ProfilePrimaryActionBar(
                padForKeyboard: false,
                child: ExcludeSemantics(
                  child: Container(
                    height: 56,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.panelBackground,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusPill,
                      ),
                      border: Border.all(color: AppColors.divider),
                    ),
                  ),
                ),
              )
            else
              CreateEventStickyFooter(
                submitting: _submitting,
                submitLabel: context.l10n.createEventSubmitLabel,
                onSubmit: _handleCreate,
              ),
          ],
        ),
      ),
    );
  }
}
