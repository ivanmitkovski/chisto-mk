import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/data/event_site_resolver.dart';
import 'package:chisto_mobile/features/events/data/events_repository_registry.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/event_ui_mappers.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_calendar.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_success_dialog.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/time_range_picker.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/shared/current_user.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_back_button.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:chisto_mobile/shared/widgets/primary_button.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/create_event/create_event_widgets.dart';

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

class _CreateEventSheetState extends State<CreateEventSheet> {
  EventSiteSummary? _selectedSite;
  DateTime? _selectedDate;
  EventTime _startTime = const EventTime(hour: 12, minute: 0);
  EventTime _endTime = const EventTime(hour: 14, minute: 0);
  EcoEventCategory? _selectedCategory;
  final Set<EventGear> _selectedGear = <EventGear>{};
  CleanupScale? _selectedScale;
  EventDifficulty? _selectedDifficulty;
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  bool _showValidationErrors = false;

  bool get _isTimeRangeValid => EcoEvent.isValidRange(_startTime, _endTime);

  bool get _isValid =>
      _selectedSite != null &&
      _selectedDate != null &&
      _selectedCategory != null &&
      _titleController.text.trim().isNotEmpty &&
      _isTimeRangeValid;

  static DateTime _nextSaturday(DateTime now) {
    final int daysUntilSaturday = (DateTime.saturday - now.weekday) % 7;
    return DateTime(now.year, now.month, now.day + (daysUntilSaturday == 0 ? 7 : daysUntilSaturday));
  }

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
    _selectedDate = _nextSaturday(now);
    _startTime = const EventTime(hour: 10, minute: 0);
    _endTime = const EventTime(hour: 12, minute: 0);
  }

  int get _completedSteps {
    int n = 0;
    if (_selectedSite != null) n++;
    if (_selectedDate != null) n++;
    if (_selectedCategory != null) n++;
    if (_titleController.text.trim().isNotEmpty) n++;
    if (_isTimeRangeValid) n++;
    return n;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (!_isValid) {
      AppHaptics.warning();
      setState(() => _showValidationErrors = true);
      return;
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
        ? 'Community cleanup action organized by local volunteers.'
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
      participantCount: 1,
      status: EcoEventStatus.upcoming,
      createdAt: now,
      isJoined: true,
      gear: _selectedGear.toList(growable: false),
      scale: _selectedScale,
      difficulty: _selectedDifficulty,
    );

    AppHaptics.success();

    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.overlay,
      builder: (BuildContext context) => EventSuccessDialog(
        title: createdEvent.title,
        siteName: createdEvent.siteName,
      ),
    );

    if (confirmed == true && mounted) {
      EventsRepositoryRegistry.instance.create(createdEvent);
      Navigator.of(context).pop(createdEvent);
    }
  }

  void _showSitePicker() {
    AppHaptics.tap();
    final List<EventSiteSummary> allSites = EventSiteResolver.allSites()
        .map(EventSiteSummary.fromPollutionSite)
        .toList(growable: false);
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext ctx) {
        return SitePickerSheet(
          allSites: allSites,
          selectedSiteId: _selectedSite?.id,
          onSelect: (EventSiteSummary site) {
            AppHaptics.tap();
            setState(() => _selectedSite = site);
            Navigator.of(ctx).pop();
          },
          onClose: () => Navigator.of(ctx).pop(),
        );
      },
    );
  }

  void _showCategoryPicker() {
    AppHaptics.tap();
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext ctx) {
        return ReportSheetScaffold(
          title: 'Event type',
          subtitle: 'What kind of action are you organizing?',
          trailing: ReportCircleIconButton(
            icon: CupertinoIcons.xmark,
            semanticLabel: 'Close',
            onTap: () => Navigator.of(ctx).pop(),
          ),
          maxHeightFactor: 0.82,
          child: ListView(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            children: <Widget>[
              ...EcoEventCategory.values.expand((EcoEventCategory cat) {
                final bool isActive = cat == _selectedCategory;
                return <Widget>[
                  ReportActionTile(
                    icon: cat.icon,
                    title: cat.label,
                    subtitle: cat.description,
                    tone: isActive
                        ? ReportSurfaceTone.accent
                        : ReportSurfaceTone.neutral,
                    trailing: Icon(
                      isActive
                          ? CupertinoIcons.checkmark_circle_fill
                          : CupertinoIcons.circle,
                      size: 22,
                      color:
                          isActive ? AppColors.primaryDark : AppColors.divider,
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
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setModalState) {
            return ReportSheetScaffold(
              title: 'Gear needed',
              subtitle: 'Select everything volunteers should bring.',
              trailing: ReportCircleIconButton(
                icon: CupertinoIcons.xmark,
                semanticLabel: 'Close',
                onTap: () => Navigator.of(ctx).pop(),
              ),
              maxHeightFactor: 0.82,
              footer: SizedBox(
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    ),
                  ),
                  child: Text(
                    _selectedGear.isEmpty
                        ? 'Skip'
                        : 'Done (${_selectedGear.length} selected)',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              child: ListView(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                children: <Widget>[
                  const ReportInfoBanner(
                    title: 'Multi-select',
                    message:
                        'Tap each item volunteers should bring. You can select as many as needed.',
                    icon: CupertinoIcons.bag,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...EventGear.values.expand((EventGear gear) {
                    final bool isActive = _selectedGear.contains(gear);
                    return <Widget>[
                      ReportActionTile(
                        icon: gear.icon,
                        title: gear.label,
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
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext ctx) {
        return ReportSheetScaffold(
          title: 'Team size',
          subtitle: 'How many volunteers do you expect?',
          trailing: ReportCircleIconButton(
            icon: CupertinoIcons.xmark,
            semanticLabel: 'Close',
            onTap: () => Navigator.of(ctx).pop(),
          ),
          maxHeightFactor: 0.6,
          child: ListView(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            children: <Widget>[
              ...CleanupScale.values.expand((CleanupScale scale) {
                final bool isActive = scale == _selectedScale;
                return <Widget>[
                  ReportActionTile(
                    icon: Icons.groups_rounded,
                    title: scale.label,
                    subtitle: scale.description,
                    tone: isActive
                        ? ReportSurfaceTone.accent
                        : ReportSurfaceTone.neutral,
                    trailing: Icon(
                      isActive
                          ? CupertinoIcons.checkmark_circle_fill
                          : CupertinoIcons.circle,
                      size: 22,
                      color:
                          isActive ? AppColors.primaryDark : AppColors.divider,
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
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext ctx) {
        return ReportSheetScaffold(
          title: 'Difficulty',
          subtitle: 'Set expectations for volunteers.',
          trailing: ReportCircleIconButton(
            icon: CupertinoIcons.xmark,
            semanticLabel: 'Close',
            onTap: () => Navigator.of(ctx).pop(),
          ),
          maxHeightFactor: 0.55,
          child: ListView(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            children: <Widget>[
              ...EventDifficulty.values.expand((EventDifficulty diff) {
                final bool isActive = diff == _selectedDifficulty;
                return <Widget>[
                  ReportActionTile(
                    icon: isActive
                        ? CupertinoIcons.checkmark_shield_fill
                        : CupertinoIcons.shield,
                    title: diff.label,
                    subtitle: diff.description,
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

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      body: Column(
        children: <Widget>[
          _buildAppBar(context, topPadding),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
            child: Row(
              children: <Widget>[
                Text(
                  'Step $steps of 5',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                    child: LinearProgressIndicator(
                      value: steps / 5,
                      minHeight: 4,
                      backgroundColor: AppColors.divider.withValues(alpha: 0.5),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _buildSiteCard(context),
                  const SizedBox(height: AppSpacing.lg),
                  EventCalendar(
                    selectedDate: _selectedDate,
                    onDateSelected: (DateTime date) {
                      setState(() => _selectedDate = date);
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Center(
                    child: Container(
                      width: 40,
                      height: AppSpacing.sheetHandleHeight,
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TimeRangePicker(
                    startTime: _startTime.toTimeOfDay(),
                    endTime: _endTime.toTimeOfDay(),
                    hasError: _showValidationErrors && !_isTimeRangeValid,
                    onStartChanged: (TimeOfDay t) =>
                        setState(() => _startTime = EventTimeUI.fromTimeOfDay(t)),
                    onEndChanged: (TimeOfDay t) =>
                        setState(() => _endTime = EventTimeUI.fromTimeOfDay(t)),
                  ),
                  if (_showValidationErrors && !_isTimeRangeValid) ...<Widget>[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'End time must be later than start time.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.accentDanger,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  _buildTitleField(context),
                  const SizedBox(height: AppSpacing.lg),
                  _buildPickerTile(
                    context,
                    label: 'Event type',
                    value: _selectedCategory?.label,
                    icon: _selectedCategory?.icon,
                    placeholder: 'Select event type',
                    onTap: _showCategoryPicker,
                    hasError: _showValidationErrors && _selectedCategory == null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildPickerTile(
                    context,
                    label: 'Team size',
                    value: _selectedScale?.label,
                    icon: Icons.groups_rounded,
                    placeholder: 'How many people?',
                    onTap: _showScalePicker,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildPickerTile(
                    context,
                    label: 'Difficulty',
                    value: _selectedDifficulty?.label,
                    icon: CupertinoIcons.shield,
                    trailingDot: _selectedDifficulty?.color,
                    placeholder: 'Set difficulty level',
                    onTap: _showDifficultyPicker,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildGearTile(context),
                  const SizedBox(height: AppSpacing.lg),
                  _buildDescriptionField(context),
                  const SizedBox(height: AppSpacing.xl),
                  PrimaryButton(
                    label: 'Create eco action',
                    enabled: true,
                    onPressed: _handleCreate,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
          const AppBackButton(),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Create event',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
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
                AppSnack.show(
                  context,
                  message:
                      'Creation keeps the event local for now, but the organizer flow is ready right away.',
                  type: AppSnackType.info,
                );
              },
              icon: const Icon(
                CupertinoIcons.bell,
                size: 18,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSiteCard(BuildContext context) {
    final EventSiteSummary? site = _selectedSite;
    final bool hasError = _showValidationErrors && site == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Cleanup site',
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Semantics(
          button: true,
          label: 'Select cleanup site',
          child: GestureDetector(
            onTap: _showSitePicker,
            child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: hasError
                  ? AppColors.accentDanger.withValues(alpha: 0.04)
                  : AppColors.panelBackground,
              borderRadius: BorderRadius.circular(AppSpacing.radius18),
              border: Border.all(
                color: hasError
                    ? AppColors.accentDanger
                    : site == null
                        ? AppColors.divider
                        : AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 44,
                  height: AppSpacing.avatarMd,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radius14),
                  ),
                  child: const Icon(
                    CupertinoIcons.location_solid,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        site?.title ?? 'Choose a pollution site',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: site == null
                                  ? AppColors.textMuted
                                  : AppColors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        site == null
                            ? 'Every event should be anchored to one cleanup location.'
                            : '${site.distanceKm.toStringAsFixed(1)} km away · ${site.description}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                              height: 1.35,
                            ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Icon(
                  CupertinoIcons.chevron_down,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              'Choose the site before creating the event.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.accentDanger,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
      ],
    );
  }

  Widget _buildTitleField(BuildContext context) {
    final bool titleError =
        _showValidationErrors && _titleController.text.trim().isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Event title',
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          maxLength: 60,
          onChanged: (_) => setState(() {}),
          buildCounter: (
            BuildContext context, {
            required int currentLength,
            required bool isFocused,
            int? maxLength,
          }) =>
              Text(
            '$currentLength / ${maxLength ?? 60}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: currentLength >= (maxLength ?? 60) * 0.9
                      ? AppColors.accentDanger
                      : AppColors.textMuted,
                  fontSize: 12,
                ),
          ),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'e.g. Weekend river cleanup',
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
            ),
            filled: true,
            fillColor: titleError
                ? AppColors.accentDanger.withValues(alpha: 0.04)
                : AppColors.panelBackground,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radius14),
              borderSide: BorderSide(
                color: titleError
                    ? AppColors.accentDanger
                    : AppColors.divider,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radius14),
              borderSide: const BorderSide(color: AppColors.accentDanger),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radius14),
              borderSide: BorderSide(
                color: titleError
                    ? AppColors.accentDanger
                    : AppColors.divider,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radius14),
              borderSide: BorderSide(
                color: titleError
                    ? AppColors.accentDanger
                    : AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
        if (titleError)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              'Event title is required.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.accentDanger,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
      ],
    );
  }

  Widget _buildPickerTile(
    BuildContext context, {
    required String label,
    required String? value,
    required IconData? icon,
    required String placeholder,
    required VoidCallback onTap,
    Color? trailingDot,
    bool hasError = false,
  }) {
    final bool hasValue = value != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Semantics(
          button: true,
          label: label,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: hasError
                  ? AppColors.accentDanger.withValues(alpha: 0.04)
                  : AppColors.panelBackground,
              borderRadius: BorderRadius.circular(AppSpacing.radius14),
              border: Border.all(
                color: hasError
                    ? AppColors.accentDanger
                    : (hasValue ? AppColors.primary.withValues(alpha: 0.3) : AppColors.divider),
              ),
            ),
            child: Row(
              children: <Widget>[
                if (icon != null && hasValue) ...<Widget>[
                  Icon(icon, size: 18, color: AppColors.primaryDark),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    hasValue ? value : placeholder,
                    style: TextStyle(
                      fontSize: 16,
                      color: hasValue
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (trailingDot != null && hasValue) ...<Widget>[
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: trailingDot,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                const Icon(
                  CupertinoIcons.chevron_down,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              'Select an event type.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.accentDanger,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
      ],
    );
  }

  Widget _buildGearTile(BuildContext context) {
    final bool hasGear = _selectedGear.isNotEmpty;
    final String summary = hasGear
        ? _selectedGear.map((EventGear g) => g.label).join(', ')
        : 'What should volunteers bring?';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Gear needed',
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Semantics(
          button: true,
          label: 'Select gear needed',
          child: GestureDetector(
            onTap: _showGearPicker,
            child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: AppColors.panelBackground,
              borderRadius: BorderRadius.circular(AppSpacing.radius14),
              border: Border.all(
                color: hasGear ? AppColors.primary.withValues(alpha: 0.3) : AppColors.divider,
              ),
            ),
            child: Row(
              children: <Widget>[
                if (hasGear) ...<Widget>[
                  const Icon(
                    CupertinoIcons.bag_fill,
                    size: 18,
                    color: AppColors.primaryDark,
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      color: hasGear
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ),
                  ),
                ),
                if (hasGear) ...<Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppSpacing.radius10),
                    ),
                    child: Text(
                      '${_selectedGear.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                const Icon(
                  CupertinoIcons.chevron_down,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Description',
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'Optional: give volunteers more context.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          maxLines: 3,
          maxLength: 300,
          onChanged: (_) => setState(() {}),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Describe what to expect, meeting point, etc.',
            hintStyle:
                Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
            filled: true,
            fillColor: AppColors.panelBackground,
            counterStyle:
                Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
            contentPadding: const EdgeInsets.all(AppSpacing.md),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radius14),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radius14),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radius14),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
