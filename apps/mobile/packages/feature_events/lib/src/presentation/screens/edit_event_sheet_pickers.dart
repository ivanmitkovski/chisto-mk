part of 'edit_event_sheet.dart';

// State is split across part-file extensions on _EditEventSheetState; setState
// runs on that State instance, which the analyzer cannot see through here.
// ignore_for_file: invalid_use_of_protected_member
extension _EditEventSheetPickers on _EditEventSheetState {
  void _showCategoryPicker() {
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
                final bool isActive = cat == _category;
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
                      setState(() => _category = cat);
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

  void _showScalePicker() {
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
                final bool isActive = scale == _scale;
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
                      setState(() => _scale = scale);
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
                final bool isActive = diff == _difficulty;
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
                      setState(() => _difficulty = diff);
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

  void _showGearPicker() {
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
                label: _gear.isEmpty
                    ? ctx.l10n.commonSkip
                    : ctx.l10n.createEventGearDoneSelectedCount(_gear.length),
                onPressed: () {
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
                    final bool isActive = _gear.contains(gear);
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
                          if (!isActive &&
                              _gear.length >= kEditEventGearMaxCount) {
                            AppSnack.show(
                              context,
                              message: ctx.l10n.editEventGearLimitReached(
                                kEditEventGearMaxCount,
                              ),
                              type: AppSnackType.warning,
                            );
                            return;
                          }
                          setModalState(() {
                            if (isActive) {
                              _gear.remove(gear);
                            } else {
                              _gear.add(gear);
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
}
