part of 'edit_event_sheet.dart';

// State is split across part-file extensions on _EditEventSheetState; setState
// runs on that State instance, which the analyzer cannot see through here.
// ignore_for_file: invalid_use_of_protected_member
extension _EditEventSheetPickers on _EditEventSheetState {
  void _showCategoryPicker() {
    AppBottomSheet.show<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AppGroupedOptionPickerSheet<EcoEventCategory>(
          title: ctx.l10n.createEventCategoryTitle,
          subtitle: ctx.l10n.createEventCategorySubtitle,
          closeSemanticLabel: ctx.l10n.commonClose,
          options: EcoEventCategory.values
              .map(
                (EcoEventCategory cat) => AppGroupedOption<EcoEventCategory>(
                  icon: cat.icon,
                  title: cat.localizedLabel(ctx.l10n),
                  subtitle: cat.localizedDescription(ctx.l10n),
                  value: cat,
                ),
              )
              .toList(growable: false),
          isSelected: (EcoEventCategory cat) => cat == _category,
          onOptionTap: (EcoEventCategory cat) {
            setState(() => _category = cat);
            Navigator.of(ctx).pop();
          },
        );
      },
    );
  }

  void _showScalePicker() {
    AppBottomSheet.show<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AppGroupedOptionPickerSheet<CleanupScale>(
          title: ctx.l10n.createEventTeamSizeTitle,
          subtitle: ctx.l10n.createEventTeamSizeSubtitle,
          closeSemanticLabel: ctx.l10n.commonClose,
          maxHeightFactor: 0.65,
          options: CleanupScale.values
              .map(
                (CleanupScale scale) => AppGroupedOption<CleanupScale>(
                  icon: Icons.groups_rounded,
                  title: scale.localizedLabel(ctx.l10n),
                  subtitle: scale.localizedDescription(ctx.l10n),
                  value: scale,
                ),
              )
              .toList(growable: false),
          isSelected: (CleanupScale scale) => scale == _scale,
          onOptionTap: (CleanupScale scale) {
            setState(() => _scale = scale);
            Navigator.of(ctx).pop();
          },
        );
      },
    );
  }

  void _showDifficultyPicker() {
    AppBottomSheet.show<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AppGroupedOptionPickerSheet<EventDifficulty>(
          title: ctx.l10n.createEventDifficultyTitle,
          subtitle: ctx.l10n.createEventDifficultySubtitle,
          closeSemanticLabel: ctx.l10n.commonClose,
          maxHeightFactor: 0.6,
          options: EventDifficulty.values
              .map(
                (EventDifficulty diff) => AppGroupedOption<EventDifficulty>(
                  icon: diff == _difficulty
                      ? CupertinoIcons.checkmark_shield_fill
                      : CupertinoIcons.shield,
                  title: diff.localizedLabel(ctx.l10n),
                  subtitle: diff.localizedDescription(ctx.l10n),
                  value: diff,
                ),
              )
              .toList(growable: false),
          isSelected: (EventDifficulty diff) => diff == _difficulty,
          trailingBuilder: (EventDifficulty diff, {required bool isActive}) {
            return Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: diff.color,
                shape: BoxShape.circle,
              ),
            );
          },
          onOptionTap: (EventDifficulty diff) {
            setState(() => _difficulty = diff);
            Navigator.of(ctx).pop();
          },
        );
      },
    );
  }

  void _showGearPicker() {
    AppBottomSheet.show<void>(
      context: context,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setModalState) {
            return AppGroupedOptionPickerSheet<EventGear>(
              title: ctx.l10n.createEventGearTitle,
              subtitle: ctx.l10n.createEventGearSubtitle,
              closeSemanticLabel: ctx.l10n.commonClose,
              footer: CreateEventGearSheetFooter(
                label: _gear.isEmpty
                    ? ctx.l10n.commonSkip
                    : ctx.l10n.createEventGearDoneSelectedCount(_gear.length),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
              options: EventGear.values
                  .map(
                    (EventGear gear) => AppGroupedOption<EventGear>(
                      icon: gear.icon,
                      title: gear.localizedLabel(ctx.l10n),
                      value: gear,
                    ),
                  )
                  .toList(growable: false),
              isSelected: (EventGear gear) => _gear.contains(gear),
              onOptionTap: (EventGear gear) {
                final bool isActive = _gear.contains(gear);
                if (!isActive && _gear.length >= kEditEventGearMaxCount) {
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
            );
          },
        );
      },
    );
  }
}
