part of 'create_event_sheet.dart';

// State is split across part-file extensions on _CreateEventSheetState; setState
// runs on that State instance, which the analyzer cannot see through here.
// ignore_for_file: invalid_use_of_protected_member
extension _CreateEventSheetBuild on _CreateEventSheetState {
  Widget _buildFormScroll(BuildContext context, int steps) {
    final AppLocalizations l10n = context.l10n;
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.translucent,
      child: CustomScrollView(
        controller: _formScrollController,
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
                    showError: _showSiteError(l10n),
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
                            showError: _showScheduleError(l10n),
                            isTimeRangeValid: _isTimeRangeValid,
                            scheduleIssue: _createScheduleIssue(),
                            minimumStartPickerTime: b.minStart,
                            minimumEndPickerTime: b.minEnd,
                            maximumEndPickerTime:
                                pickerMaximumForEndSameCalendarDay(),
                            onDateSelected: (DateTime date) {
                              setState(() {
                                _selectedDate = DateUtils.dateOnly(date);
                                final ({EventTime start, EventTime end})
                                clamped = clampCreateOrUpcomingSchedule(
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
                      if (_scheduleConflict.hint != null) ...<Widget>[
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.accentWarning.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                            border: Border.all(
                              color: AppColors.accentWarning.withValues(
                                alpha: 0.45,
                              ),
                            ),
                          ),
                          child: Text(
                            context.l10n.eventsScheduleConflictPreviewBody(
                              _scheduleConflict.hint!.title,
                              _scheduleConflict.formatConflictWhen(
                                context,
                                _scheduleConflict.hint!.scheduledAt,
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
                        titleFocusNode: _titleFocus,
                        descriptionFieldKey: _descriptionFieldKey,
                        descriptionFocusNode: _descriptionFocus,
                        descriptionController: _descriptionController,
                        showTitleError: _showTitleError(l10n),
                        showCategoryError: _showCategoryError(l10n),
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
