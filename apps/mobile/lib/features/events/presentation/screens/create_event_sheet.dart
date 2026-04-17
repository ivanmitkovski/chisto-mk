import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/di/service_locator.dart';
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
import 'package:chisto_mobile/features/events/presentation/utils/create_event_form_validation.dart';
import 'package:chisto_mobile/features/events/presentation/utils/event_schedule_constraints.dart';
import 'package:chisto_mobile/features/events/presentation/utils/events_localized_strings.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/create_event/create_event_async_site_picker.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/events_modal_sheet.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/create_event/create_event_details_section.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/create_event/create_event_help_sheet.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/create_event/create_event_schedule_section.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/create_event/create_event_screen_skeleton.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/create_event/create_event_site_section.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/create_event/create_event_sticky_footer.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/create_event/create_event_step_progress_header.dart';
import 'package:chisto_mobile/features/profile/presentation/widgets/profile_primary_action_bar.dart';
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
  });

  final String? preselectedSiteId;
  final String? preselectedSiteName;
  final String? preselectedSiteImageUrl;
  final double? preselectedSiteDistanceKm;

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

  late final _CreateEventFormSnapshot _initialSnapshot;
  late final AnimationController _sectionEntranceController;

  final GlobalKey _siteSectionKey = GlobalKey();
  final GlobalKey _scheduleSectionKey = GlobalKey();
  final GlobalKey _titleFieldKey = GlobalKey();
  final GlobalKey _categorySectionKey = GlobalKey();

  Timer? _scheduleConflictTimer;
  ConflictingEventInfo? _scheduleConflictHint;
  int _scheduleConflictRequestId = 0;

  bool get _isTimeRangeValid => EcoEvent.isValidRange(_startTime, _endTime);

  ScheduleValidationIssue? _createScheduleIssue() {
    final DateTime? d = _selectedDate;
    if (d == null) {
      return null;
    }
    return validateCreateOrUpcomingEditSchedule(
      dateOnly: DateUtils.dateOnly(d),
      start: _startTime,
      end: _endTime,
      now: DateTime.now(),
    );
  }

  bool get _isScheduleValid => _createScheduleIssue() == null;

  ({DateTime? minStart, DateTime? minEnd}) _schedulePickerBounds() {
    final DateTime? d = _selectedDate;
    if (d == null) {
      return (minStart: null, minEnd: null);
    }
    final DateTime dateOnly = DateUtils.dateOnly(d);
    final DateTime now = DateTime.now();
    return (
      minStart: pickerMinimumForStart(dateOnly: dateOnly, now: now),
      minEnd: pickerMinimumForEnd(
        dateOnly: dateOnly,
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

  bool get _isDirty => !_initialSnapshot.matches(this);

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
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
    _initialSnapshot = _CreateEventFormSnapshot.capture(this);
    _sectionEntranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_completeBootstrapSkeleton());
    });
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
      final DateTime startLocal = DateTime(
        date.year,
        date.month,
        date.day,
        _startTime.hour,
        _startTime.minute,
      );
      final DateTime endLocal = DateTime(
        date.year,
        date.month,
        date.day,
        _endTime.hour,
        _endTime.minute,
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

    final DateTime now = DateTime.now();
    final DateTime selectedDate = _selectedDate ?? DateUtils.dateOnly(now);
    final EventSiteSummary? selectedSite = _selectedSite;
    if (selectedSite == null) {
      AppHaptics.warning();
      setState(() => _showValidationErrors = true);
      return;
    }
    final String eventId = 'evt-local-${DateTime.now().microsecondsSinceEpoch}';
    final String title = _titleController.text.trim();
    final String description = _descriptionController.text.trim().isEmpty
        ? context.l10n.createEventDefaultDescription
        : _descriptionController.text.trim();
    final EcoEventCategory category =
        _selectedCategory ?? EcoEventCategory.generalCleanup;
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
      date: DateTime(selectedDate.year, selectedDate.month, selectedDate.day),
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
      builder: (BuildContext context) =>
          EventSuccessDialog(title: created.title, siteName: created.siteName),
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
    return EventSiteResolver.allSites()
        .map(EventSiteSummary.fromPollutionSite)
        .toList(growable: false);
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
        return _VolunteerCapPickerSheet(
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
              footer: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewPaddingOf(ctx).bottom,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      AppHaptics.tap();
                      Navigator.of(ctx).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textPrimary,
                      alignment: Alignment.center,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusPill,
                        ),
                      ),
                    ),
                    child: Text(
                      _selectedGear.isEmpty
                          ? ctx.l10n.commonSkip
                          : ctx.l10n.createEventGearDoneSelectedCount(
                              _selectedGear.length,
                            ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
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
                            onDateSelected: (DateTime date) {
                              setState(() {
                                _selectedDate = date;
                                final ({EventTime start, EventTime end}) clamped =
                                    clampCreateOrUpcomingSchedule(
                                  dateOnly: DateUtils.dateOnly(date),
                                  start: _startTime,
                                  end: _endTime,
                                  now: DateTime.now(),
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
                                if (d != null &&
                                    !EcoEvent.isValidRange(_startTime, _endTime)) {
                                  final DateTime sdt = eventScheduleInstantLocal(
                                    DateUtils.dateOnly(d),
                                    _startTime,
                                  );
                                  _endTime = eventTimeFromDateTime(
                                    sdt.add(const Duration(hours: 2)),
                                  );
                                }
                              });
                              _scheduleConflictPreviewDebounced();
                            },
                            onEndChanged: (EventTime t) {
                              setState(() => _endTime = t);
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

class _VolunteerCapPickerSheet extends StatelessWidget {
  const _VolunteerCapPickerSheet({
    required this.initial,
    required this.onApply,
  });

  final int? initial;
  final void Function(int?) onApply;

  static const List<int> _presets = <int>[15, 30, 50, 100];

  @override
  Widget build(BuildContext context) {
    return ReportSheetScaffold(
      title: context.l10n.createEventVolunteerCapSheetTitle,
      subtitle: context.l10n.createEventVolunteerCapSheetSubtitle,
      trailing: ReportCircleIconButton(
        icon: CupertinoIcons.xmark,
        semanticLabel: context.l10n.commonClose,
        onTap: () => Navigator.of(context).pop(),
      ),
      maxHeightFactor: 0.72,
      addBottomInset: false,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      child: _VolunteerCapPickerBody(
        initial: initial,
        presets: _presets,
        onApply: onApply,
      ),
    );
  }
}

class _VolunteerCapPickerBody extends StatefulWidget {
  const _VolunteerCapPickerBody({
    required this.initial,
    required this.presets,
    required this.onApply,
  });

  final int? initial;
  final List<int> presets;
  final void Function(int?) onApply;

  @override
  State<_VolunteerCapPickerBody> createState() =>
      _VolunteerCapPickerBodyState();
}

class _VolunteerCapPickerBodyState extends State<_VolunteerCapPickerBody> {
  late int? _selected;
  final TextEditingController _customController = TextEditingController();
  String? _customError;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
    final int? initial = widget.initial;
    if (initial != null && !widget.presets.contains(initial)) {
      _customController.text = '$initial';
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _applyCustom() {
    final int? parsed = int.tryParse(_customController.text.trim());
    if (parsed == null || parsed < 2 || parsed > 5000) {
      setState(
        () => _customError = context.l10n.createEventVolunteerCapInvalid,
      );
      return;
    }
    widget.onApply(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      children: <Widget>[
        ReportActionTile(
          icon: CupertinoIcons.infinite,
          title: context.l10n.createEventVolunteerCapNoLimit,
          tone: _selected == null
              ? ReportSurfaceTone.accent
              : ReportSurfaceTone.neutral,
          trailing: Icon(
            _selected == null
                ? CupertinoIcons.checkmark_circle_fill
                : CupertinoIcons.circle,
            size: 22,
            color: _selected == null
                ? AppColors.primaryDark
                : AppColors.divider,
          ),
          onTap: () {
            AppHaptics.tap();
            widget.onApply(null);
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        ...widget.presets.expand((int n) {
          final bool isActive = _selected == n;
          return <Widget>[
            ReportActionTile(
              icon: CupertinoIcons.person_3_fill,
              title: '$n',
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
                widget.onApply(n);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ];
        }),
        const SizedBox(height: AppSpacing.md),
        Text(
          context.l10n.createEventVolunteerCapCustomLabel,
          style: AppTypography.eventsFormLeadHeading(Theme.of(context).textTheme),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _customController,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() => _customError = null),
          decoration: InputDecoration(
            hintText: context.l10n.createEventVolunteerCapCustomHint,
            filled: true,
            fillColor: AppColors.panelBackground,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radius14),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radius14),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
        if (_customError != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              _customError!,
              style: AppTypography.eventsCaptionStrong(
                Theme.of(context).textTheme,
                color: AppColors.accentDanger,
              ).copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _applyCustom,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
            ),
            child: Text(
              context.l10n.createEventVolunteerCapApply,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CreateEventFormSnapshot {
  _CreateEventFormSnapshot._({
    required this.siteId,
    required this.dateMillis,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.categoryIndex,
    required this.gearNames,
    required this.scaleIndex,
    required this.difficultyIndex,
    required this.title,
    required this.description,
    required this.maxParticipants,
  });

  factory _CreateEventFormSnapshot.capture(_CreateEventSheetState s) {
    final List<String> gearNames =
        s._selectedGear.map((EventGear g) => g.name).toList()..sort();
    return _CreateEventFormSnapshot._(
      siteId: s._selectedSite?.id,
      dateMillis: s._selectedDate?.millisecondsSinceEpoch,
      startHour: s._startTime.hour,
      startMinute: s._startTime.minute,
      endHour: s._endTime.hour,
      endMinute: s._endTime.minute,
      categoryIndex: s._selectedCategory?.index,
      gearNames: gearNames,
      scaleIndex: s._selectedScale?.index,
      difficultyIndex: s._selectedDifficulty?.index,
      title: s._titleController.text,
      description: s._descriptionController.text,
      maxParticipants: s._maxParticipants,
    );
  }

  final String? siteId;
  final int? dateMillis;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final int? categoryIndex;
  final List<String> gearNames;
  final int? scaleIndex;
  final int? difficultyIndex;
  final String title;
  final String description;
  final int? maxParticipants;

  bool matches(_CreateEventSheetState s) {
    final List<String> gear =
        s._selectedGear.map((EventGear g) => g.name).toList()..sort();
    return siteId == s._selectedSite?.id &&
        dateMillis == s._selectedDate?.millisecondsSinceEpoch &&
        startHour == s._startTime.hour &&
        startMinute == s._startTime.minute &&
        endHour == s._endTime.hour &&
        endMinute == s._endTime.minute &&
        categoryIndex == s._selectedCategory?.index &&
        _listEq(gearNames, gear) &&
        scaleIndex == s._selectedScale?.index &&
        difficultyIndex == s._selectedDifficulty?.index &&
        title == s._titleController.text &&
        description == s._descriptionController.text &&
        maxParticipants == s._maxParticipants;
  }

  static bool _listEq(List<String> a, List<String> b) {
    if (a.length != b.length) {
      return false;
    }
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}
