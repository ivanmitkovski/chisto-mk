import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/l10n/app_error_localizations.dart';
import 'package:chisto_mobile/features/events/domain/models/event_schedule_conflict_preview.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/data/event_site_resolver.dart';
import 'package:chisto_mobile/features/events/data/events_repository_registry.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/event_ui_mappers.dart';
import 'package:chisto_mobile/features/events/presentation/utils/create_event_form_snapshot.dart';
import 'package:chisto_mobile/features/events/presentation/utils/create_event_form_validation.dart';
import 'package:chisto_mobile/features/events/presentation/utils/event_schedule_constraints.dart';
import 'package:chisto_mobile/features/events/presentation/utils/events_localized_strings.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/create_event/create_event_async_site_picker.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/events_modal_sheet.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/create_event/create_event_details_section.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/create_event/create_event_gear_sheet_footer.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/create_event/create_event_help_sheet.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/create_event/create_event_schedule_section.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/create_event/create_event_screen_skeleton.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/create_event/create_event_site_section.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/create_event/create_event_sticky_footer.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/create_event/create_event_step_progress_header.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/create_event/create_event_volunteer_cap_picker_sheet.dart';
import 'package:chisto_mobile/features/profile/presentation/widgets/profile_primary_action_bar.dart';
import 'package:chisto_mobile/features/events/presentation/screens/organizer_toolkit/organizer_toolkit_screen.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_success_dialog.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/shared/current_user.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_back_button.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:chisto_mobile/features/home/domain/repositories/sites_repository.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart' hide TextDirection;

class CreateEventSheet extends StatefulWidget {
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
  State<CreateEventSheet> createState() => _CreateEventSheetState();
}

class _CreateEventSheetState extends State<CreateEventSheet>
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

  Timer? _scheduleConflictTimer;
  ConflictingEventInfo? _scheduleConflictHint;
  int _scheduleConflictRequestId = 0;
  int _localSyntheticEventNonce = 0;

  DateTime _now() => widget.clock?.call() ?? DateTime.now();

  bool get _isTimeRangeValid {
    final DateTime? d = _selectedDate;
    if (d == null) {
      return false;
    }
    final DateTime si =
        eventScheduleInstantLocal(DateUtils.dateOnly(d), _startTime);
    final DateTime ei =
        eventScheduleInstantLocal(DateUtils.dateOnly(d), _endTime);
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
    final DateTime now = _now();
    _selectedSite = EventSiteResolver.coerceSummary(
      siteId: widget.preselectedSiteId,
      siteName: widget.preselectedSiteName,
      siteImageUrl: widget.preselectedSiteImageUrl,
      siteDistanceKm: widget.preselectedSiteDistanceKm,
    );
    _selectedDate = DateUtils.dateOnly(now);
    final ({EventTime start, EventTime end}) slot =
        defaultStartEndForDate(dateOnly: _selectedDate!, now: now);
    _startTime = slot.start;
    _endTime = slot.end;
    final ({EventTime start, EventTime end}) boot = clampCreateOrUpcomingSchedule(
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
      _redirectIfOrganizerNotCertified();
      unawaited(_completeBootstrapSkeleton());
    });
  }

  /// Deep link to [AppRoutes.eventsCreate] bypasses [EventsNavigation.openCreate];
  /// uncertified organizers are sent through the toolkit first.
  void _redirectIfOrganizerNotCertified() {
    if (!mounted) {
      return;
    }
    if (!ServiceLocator.instance.isInitialized) {
      return;
    }
    if (ServiceLocator.instance.authState.isOrganizerCertified) {
      return;
    }
    final NavigatorState nav = Navigator.of(context);
    nav.pushReplacement(
      MaterialPageRoute<void>(
        builder: (BuildContext toolkitContext) => OrganizerToolkitScreen(
          onCertified: () {
            Navigator.of(toolkitContext).pushReplacementNamed(
              AppRoutes.eventsCreate,
              arguments: EventCreateRouteArguments(
                preselectedSiteId: widget.preselectedSiteId,
                preselectedSiteName: widget.preselectedSiteName,
                preselectedSiteImageUrl: widget.preselectedSiteImageUrl,
                preselectedSiteDistanceKm: widget.preselectedSiteDistanceKm,
              ),
            );
          },
        ),
      ),
    );
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
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _scheduleConflictPreviewDebounced());
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
    _scheduleConflictTimer?.cancel();
    _sectionEntranceController.dispose();
    _descriptionController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  String _formatConflictWhen(BuildContext context, DateTime at) {
    return DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag())
        .add_jm()
        .format(at.toLocal());
  }

  void _scheduleConflictPreviewDebounced() {
    _scheduleConflictTimer?.cancel();
    final EventSiteSummary? site = _selectedSite;
    final DateTime? date = _selectedDate;
    if (site == null || date == null || !_isScheduleValid) {
      if (_scheduleConflictHint != null) {
        setState(() => _scheduleConflictHint = null);
      }
      return;
    }
    _scheduleConflictTimer = Timer(const Duration(milliseconds: 480), () {
      if (!mounted) {
        return;
      }
      final int token = ++_scheduleConflictRequestId;
      final DateTime startLocal = eventScheduleInstantLocal(
        DateUtils.dateOnly(date),
        _startTime,
      );
      final DateTime endLocal = eventScheduleInstantLocal(
        DateUtils.dateOnly(date),
        _endTime,
      );
      unawaited(() async {
        try {
          final EventScheduleConflictPreview preview =
              await EventsRepositoryRegistry.instance.checkScheduleConflict(
            siteId: site.id,
            scheduledAt: startLocal.toUtc(),
            endAt: endLocal.toUtc(),
          );
          if (!mounted || token != _scheduleConflictRequestId) {
            return;
          }
          setState(() {
            _scheduleConflictHint =
                preview.hasConflict ? preview.conflictingEvent : null;
          });
        } on Object {
          if (!mounted || token != _scheduleConflictRequestId) {
            return;
          }
          setState(() => _scheduleConflictHint = null);
        }
      }());
    });
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
    return discard == true;
  }

  Future<void> _onBackPressed() async {
    if (!_isDirty) {
      Navigator.of(context).maybePop();
      return;
    }
    // `maybePop` respects `PopScope(canPop: !_isDirty)` and would re-fire
    // `onPopInvokedWithResult` instead of dismissing.
    if (await _confirmDiscard() && mounted) {
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

    if (_scheduleConflictHint != null) {
      final ConflictingEventInfo hint = _scheduleConflictHint!;
      final bool? goAhead = await showCupertinoDialog<bool>(
        context: context,
        builder: (BuildContext ctx) => CupertinoAlertDialog(
          title: Text(ctx.l10n.eventsScheduleConflictPreviewTitle),
          content: Text(
            ctx.l10n.eventsScheduleConflictPreviewBody(
              hint.title,
              _formatConflictWhen(ctx, hint.scheduledAt),
            ),
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(ctx.l10n.eventsScheduleConflictAdjustTime),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(ctx.l10n.eventsScheduleConflictContinue),
            ),
          ],
        ),
      );
      if (goAhead != true || !mounted) {
        return;
      }
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
    final DateTime startDay =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
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
      created = await EventsRepositoryRegistry.instance.create(createdEvent);
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

    AppHaptics.success();

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

    if (confirmed == true && mounted) {
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
    if (!ServiceLocator.instance.isInitialized) {
      return CreateEventSitesLoadResult(
        sites: _offlineSiteSummaries(),
        usedOfflineFallback: true,
        networkError: false,
      );
    }
    final (double? lat, double? lng) = await _tryUserLatLng();
    try {
      final SitesListResult result = await ServiceLocator
          .instance
          .sitesRepository
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

  void _showSitePicker({bool showMapTab = false}) {
    AppHaptics.tap();
    showEventsSurfaceModal<void>(
      context: context,
      builder: (BuildContext ctx) {
        return CreateEventAsyncSitePicker(
          load: _loadSitesForCreatePicker,
          selectedSiteId: _selectedSite?.id,
          initialShowMapTab: showMapTab,
          onSelect: (EventSiteSummary site) {
            AppHaptics.tap();
            setState(() => _selectedSite = site);
            _scheduleConflictPreviewDebounced();
            Navigator.of(ctx).pop();
          },
          onClose: () => Navigator.of(ctx).pop(),
        );
      },
    );
  }

  void _showVolunteerCapPicker() {
    AppHaptics.tap();
    showEventsSurfaceModal<void>(
      context: context,
      builder: (BuildContext ctx) {
        return CreateEventVolunteerCapPickerSheet(
          initial: _maxParticipants,
          onApply: (int? value) {
            setState(() => _maxParticipants = value);
            Navigator.of(ctx).pop();
          },
        );
      },
    );
  }

  void _showCategoryPicker() {
    AppHaptics.tap();
    showEventsSurfaceModal<void>(
      context: context,
      builder: (BuildContext ctx) {
        return ReportSheetScaffold(
          title: ctx.l10n.createEventCategoryTitle,
          subtitle: ctx.l10n.createEventCategorySubtitle,
          trailing: ReportCircleIconButton(
            icon: CupertinoIcons.xmark,
            semanticLabel: ctx.l10n.commonClose,
            onTap: () => Navigator.of(ctx).pop(),
          ),
          maxHeightFactor: 0.82,
          addBottomInset: false,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            0,
          ),
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            children: <Widget>[
              ...EcoEventCategory.values.expand((EcoEventCategory cat) {
                final bool isActive = cat == _selectedCategory;
                return <Widget>[
                  ReportActionTile(
                    icon: cat.icon,
                    title: cat.localizedLabel(ctx.l10n),
                    subtitle: cat.localizedDescription(ctx.l10n),
                    tone: isActive
                        ? ReportSurfaceTone.accent
                        : ReportSurfaceTone.neutral,
                    trailing: Icon(
                      isActive
                          ? CupertinoIcons.checkmark_circle_fill
                          : CupertinoIcons.circle,
                      size: 22,
                      color: isActive
                          ? AppColors.primaryDark
                          : AppColors.divider,
                    ),
                    onTap: () {
                      AppHaptics.tap();
                      setState(() => _selectedCategory = cat);
                      Navigator.of(ctx).pop();
                    },
                  ),
                  if (cat != EcoEventCategory.values.last)
                    const SizedBox(height: AppSpacing.sm),
                ];
              }),
            ],
          ),
        );
      },
    );
  }

  void _showGearPicker() {
    AppHaptics.tap();
    showEventsSurfaceModal<void>(
      context: context,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setModalState) {
            return ReportSheetScaffold(
              title: ctx.l10n.createEventGearTitle,
              subtitle: ctx.l10n.createEventGearSubtitle,
              trailing: ReportCircleIconButton(
                icon: CupertinoIcons.xmark,
                semanticLabel: ctx.l10n.commonClose,
                onTap: () => Navigator.of(ctx).pop(),
              ),
              maxHeightFactor: 0.82,
              addBottomInset: false,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                0,
              ),
              footer: CreateEventGearSheetFooter(
                label: _selectedGear.isEmpty
                    ? ctx.l10n.commonSkip
                    : ctx.l10n.createEventGearDoneSelectedCount(
                        _selectedGear.length,
                      ),
                onPressed: () {
                  AppHaptics.tap();
                  Navigator.of(ctx).pop();
                },
              ),
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                children: <Widget>[
                  ReportInfoBanner(
                    title: ctx.l10n.createEventGearMultiselectTitle,
                    message: ctx.l10n.createEventGearMultiselectMessage,
                    icon: CupertinoIcons.bag,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...EventGear.values.expand((EventGear gear) {
                    final bool isActive = _selectedGear.contains(gear);
                    return <Widget>[
                      ReportActionTile(
                        icon: gear.icon,
                        title: gear.localizedLabel(ctx.l10n),
                        tone: isActive
                            ? ReportSurfaceTone.accent
                            : ReportSurfaceTone.neutral,
                        trailing: Icon(
                          isActive
                              ? CupertinoIcons.checkmark_circle_fill
                              : CupertinoIcons.circle,
                          size: 22,
                          color: isActive
                              ? AppColors.primaryDark
                              : AppColors.divider,
                        ),
                        onTap: () {
                          AppHaptics.tap();
                          setModalState(() {
                            if (isActive) {
                              _selectedGear.remove(gear);
                            } else {
                              _selectedGear.add(gear);
                            }
                          });
                          setState(() {});
                        },
                      ),
                      if (gear != EventGear.values.last)
                        const SizedBox(height: AppSpacing.sm),
                    ];
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showScalePicker() {
    AppHaptics.tap();
    showEventsSurfaceModal<void>(
      context: context,
      builder: (BuildContext ctx) {
        return ReportSheetScaffold(
          title: ctx.l10n.createEventTeamSizeTitle,
          subtitle: ctx.l10n.createEventTeamSizeSubtitle,
          trailing: ReportCircleIconButton(
            icon: CupertinoIcons.xmark,
            semanticLabel: ctx.l10n.commonClose,
            onTap: () => Navigator.of(ctx).pop(),
          ),
          maxHeightFactor: 0.65,
          addBottomInset: false,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            0,
          ),
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            children: <Widget>[
              ...CleanupScale.values.expand((CleanupScale scale) {
                final bool isActive = scale == _selectedScale;
                return <Widget>[
                  ReportActionTile(
                    icon: Icons.groups_rounded,
                    title: scale.localizedLabel(ctx.l10n),
                    subtitle: scale.localizedDescription(ctx.l10n),
                    tone: isActive
                        ? ReportSurfaceTone.accent
                        : ReportSurfaceTone.neutral,
                    trailing: Icon(
                      isActive
                          ? CupertinoIcons.checkmark_circle_fill
                          : CupertinoIcons.circle,
                      size: 22,
                      color: isActive
                          ? AppColors.primaryDark
                          : AppColors.divider,
                    ),
                    onTap: () {
                      AppHaptics.tap();
                      setState(() => _selectedScale = scale);
                      Navigator.of(ctx).pop();
                    },
                  ),
                  if (scale != CleanupScale.values.last)
                    const SizedBox(height: AppSpacing.sm),
                ];
              }),
            ],
          ),
        );
      },
    );
  }

  void _showDifficultyPicker() {
    AppHaptics.tap();
    showEventsSurfaceModal<void>(
      context: context,
      builder: (BuildContext ctx) {
        return ReportSheetScaffold(
          title: ctx.l10n.createEventDifficultyTitle,
          subtitle: ctx.l10n.createEventDifficultySubtitle,
          trailing: ReportCircleIconButton(
            icon: CupertinoIcons.xmark,
            semanticLabel: ctx.l10n.commonClose,
            onTap: () => Navigator.of(ctx).pop(),
          ),
          maxHeightFactor: 0.6,
          addBottomInset: false,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            0,
          ),
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            children: <Widget>[
              ...EventDifficulty.values.expand((EventDifficulty diff) {
                final bool isActive = diff == _selectedDifficulty;
                return <Widget>[
                  ReportActionTile(
                    icon: isActive
                        ? CupertinoIcons.checkmark_shield_fill
                        : CupertinoIcons.shield,
                    title: diff.localizedLabel(ctx.l10n),
                    subtitle: diff.localizedDescription(ctx.l10n),
                    tone: isActive
                        ? ReportSurfaceTone.accent
                        : ReportSurfaceTone.neutral,
                    trailing: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: diff.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    onTap: () {
                      AppHaptics.tap();
                      setState(() => _selectedDifficulty = diff);
                      Navigator.of(ctx).pop();
                    },
                  ),
                  if (diff != EventDifficulty.values.last)
                    const SizedBox(height: AppSpacing.sm),
                ];
              }),
            ],
          ),
        );
      },
    );
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
                    ? Padding(
                        key: const ValueKey<String>('create_event_bootstrap'),
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.sm,
                          AppSpacing.lg,
                          0,
                        ),
                        child: const CreateEventScreenSkeleton(),
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
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusPill),
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

  Widget _buildFormScroll(BuildContext context, int steps) {
    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const BouncingScrollPhysics(),
      slivers: <Widget>[
        SliverPersistentHeader(
          pinned: true,
          delegate: CreateEventStepProgressDelegate(steps: steps),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg + CreateEventStickyFooter.scrollBottomReserve,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _staggeredSection(
                  slot: 0,
                  child: CreateEventSiteSection(
                    sectionKey: _siteSectionKey,
                    site: _selectedSite,
                    showValidationErrors: _showValidationErrors,
                    onSelectSiteTap: () async => _showSitePicker(),
                    onMapPreviewTap: () async =>
                        _showSitePicker(showMapTab: true),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _staggeredSection(
                  slot: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _sectionGroupCaption(
                        context,
                        context.l10n.createEventSectionScheduleCaption,
                      ),
                      Builder(
                        builder: (BuildContext context) {
                          final ({DateTime? minStart, DateTime? minEnd}) b =
                              _schedulePickerBounds();
                          return CreateEventScheduleSection(
                            sectionKey: _scheduleSectionKey,
                            selectedDate: _selectedDate,
                            startTime: _startTime,
                            endTime: _endTime,
                            showValidationErrors: _showValidationErrors,
                            isTimeRangeValid: _isTimeRangeValid,
                            scheduleIssue: _createScheduleIssue(),
                            minimumStartPickerTime: b.minStart,
                            minimumEndPickerTime: b.minEnd,
                            maximumEndPickerTime: pickerMaximumForEndSameCalendarDay(),
                            onDateSelected: (DateTime date) {
                              setState(() {
                                _selectedDate = DateUtils.dateOnly(date);
                                final ({EventTime start, EventTime end}) clamped =
                                    clampCreateOrUpcomingSchedule(
                                  dateOnly: _selectedDate!,
                                  start: _startTime,
                                  end: _endTime,
                                  now: _now(),
                                );
                                _startTime = clamped.start;
                                _endTime = clamped.end;
                              });
                              _scheduleConflictPreviewDebounced();
                            },
                            onStartChanged: (EventTime t) {
                              setState(() {
                                _startTime = t;
                                final DateTime? d = _selectedDate;
                                if (d == null) {
                                  return;
                                }
                                final DateTime si = eventScheduleInstantLocal(
                                  DateUtils.dateOnly(d),
                                  _startTime,
                                );
                                final DateTime ei = eventScheduleInstantLocal(
                                  DateUtils.dateOnly(d),
                                  _endTime,
                                );
                                if (!ei.isAfter(si)) {
                                  _endTime = eventTimeFromDateTime(
                                    ceilToMinuteGrid(
                                      si.add(const Duration(hours: 1)),
                                    ),
                                  );
                                }
                                _endTime = clampEndTimeToEventDay(
                                  dateOnly: DateUtils.dateOnly(d),
                                  end: _endTime,
                                  start: _startTime,
                                );
                              });
                              _scheduleConflictPreviewDebounced();
                            },
                            onEndChanged: (EventTime t) {
                              setState(() {
                                final DateTime? d = _selectedDate;
                                _endTime = d == null
                                    ? t
                                    : clampEndTimeToEventDay(
                                        dateOnly: DateUtils.dateOnly(d),
                                        end: t,
                                        start: _startTime,
                                      );
                              });
                              _scheduleConflictPreviewDebounced();
                            },
                          );
                        },
                      ),
                      if (_scheduleConflictHint != null) ...<Widget>[
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.accentWarning.withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                            border: Border.all(
                              color: AppColors.accentWarning.withValues(alpha: 0.45),
                            ),
                          ),
                          child: Text(
                            context.l10n.eventsScheduleConflictPreviewBody(
                              _scheduleConflictHint!.title,
                              _formatConflictWhen(
                                context,
                                _scheduleConflictHint!.scheduledAt,
                              ),
                            ),
                            style: AppTypography.eventsSupportingCaption(
                              Theme.of(context).textTheme,
                            ).copyWith(color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _staggeredSection(
                  slot: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _sectionGroupCaption(
                        context,
                        context.l10n.createEventSectionDetailsCaption,
                      ),
                      CreateEventDetailsSection(
                        titleFieldKey: _titleFieldKey,
                        categorySectionKey: _categorySectionKey,
                        titleController: _titleController,
                        descriptionController: _descriptionController,
                        showValidationErrors: _showValidationErrors,
                        selectedCategory: _selectedCategory,
                        selectedScale: _selectedScale,
                        selectedDifficulty: _selectedDifficulty,
                        selectedGear: _selectedGear,
                        maxParticipants: _maxParticipants,
                        onTitleChanged: () => setState(() {}),
                        onCategoryTap: _showCategoryPicker,
                        onVolunteerCapTap: _showVolunteerCapPicker,
                        onScaleTap: _showScalePicker,
                        onDifficultyTap: _showDifficultyPicker,
                        onGearTap: _showGearPicker,
                        onDescriptionChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context, double topPadding) {
    return Container(
      color: AppColors.appBackground,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        topPadding + AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Row(
        children: <Widget>[
          AppBackButton(
            backgroundColor: AppColors.inputFill,
            onPressed: () => unawaited(_onBackPressed()),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              context.l10n.createEventAppBarTitle,
              style: AppTypography.eventsFormLeadHeading(
                Theme.of(context).textTheme,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          CircleAvatar(
            radius: 19,
            backgroundColor: AppColors.inputFill,
            child: IconButton(
              iconSize: 18,
              onPressed: () {
                AppHaptics.tap();
                showCreateEventHelpSheet(context);
              },
              icon: const Icon(
                CupertinoIcons.info_circle,
                size: 18,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
