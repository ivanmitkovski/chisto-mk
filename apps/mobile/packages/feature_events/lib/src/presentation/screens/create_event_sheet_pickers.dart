part of 'create_event_sheet.dart';

// State is split across part-file extensions on _CreateEventSheetState; setState
// runs on that State instance, which the analyzer cannot see through here.
// ignore_for_file: invalid_use_of_protected_member
extension _CreateEventSheetPickers on _CreateEventSheetState {
  void _showSitePicker({bool showMapTab = false}) {
    showEventsSurfaceModal<void>(
      context: context,
      builder: (BuildContext ctx) {
        return CreateEventAsyncSitePicker(
          load: _loadSitesForCreatePicker,
          selectedSiteId: _selectedSite?.id,
          initialShowMapTab: showMapTab,
          onSelect: (EventSiteSummary site) {
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
    showEventsSurfaceModal<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AppSheetScaffold(
          title: ctx.l10n.createEventCategoryTitle,
          subtitle: ctx.l10n.createEventCategorySubtitle,
          trailing: AppCircleIconButton(
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
                  AppActionTile(
                    icon: cat.icon,
                    title: cat.localizedLabel(ctx.l10n),
                    subtitle: cat.localizedDescription(ctx.l10n),
                    tone: isActive
                        ? AppSurfaceTone.accent
                        : AppSurfaceTone.neutral,
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
    showEventsSurfaceModal<void>(
      context: context,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setModalState) {
            return AppSheetScaffold(
              title: ctx.l10n.createEventGearTitle,
              subtitle: ctx.l10n.createEventGearSubtitle,
              trailing: AppCircleIconButton(
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
                  Navigator.of(ctx).pop();
                },
              ),
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                children: <Widget>[
                  AppBanner(
                    title: ctx.l10n.createEventGearMultiselectTitle,
                    message: ctx.l10n.createEventGearMultiselectMessage,
                    icon: CupertinoIcons.bag,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...EventGear.values.expand((EventGear gear) {
                    final bool isActive = _selectedGear.contains(gear);
                    return <Widget>[
                      AppActionTile(
                        icon: gear.icon,
                        title: gear.localizedLabel(ctx.l10n),
                        tone: isActive
                            ? AppSurfaceTone.accent
                            : AppSurfaceTone.neutral,
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
    showEventsSurfaceModal<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AppSheetScaffold(
          title: ctx.l10n.createEventTeamSizeTitle,
          subtitle: ctx.l10n.createEventTeamSizeSubtitle,
          trailing: AppCircleIconButton(
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
                  AppActionTile(
                    icon: Icons.groups_rounded,
                    title: scale.localizedLabel(ctx.l10n),
                    subtitle: scale.localizedDescription(ctx.l10n),
                    tone: isActive
                        ? AppSurfaceTone.accent
                        : AppSurfaceTone.neutral,
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
    showEventsSurfaceModal<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AppSheetScaffold(
          title: ctx.l10n.createEventDifficultyTitle,
          subtitle: ctx.l10n.createEventDifficultySubtitle,
          trailing: AppCircleIconButton(
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
                  AppActionTile(
                    icon: isActive
                        ? CupertinoIcons.checkmark_shield_fill
                        : CupertinoIcons.shield,
                    title: diff.localizedLabel(ctx.l10n),
                    subtitle: diff.localizedDescription(ctx.l10n),
                    tone: isActive
                        ? AppSurfaceTone.accent
                        : AppSurfaceTone.neutral,
                    trailing: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: diff.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    onTap: () {
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
}
