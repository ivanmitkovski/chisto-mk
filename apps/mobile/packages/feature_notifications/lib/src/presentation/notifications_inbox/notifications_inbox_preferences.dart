part of 'package:feature_notifications/src/presentation/notifications_inbox/notifications_inbox_screen.dart';

// State is split across part-file extensions on _NotificationsScreenState;
// setState runs on that State instance, which the analyzer cannot see here.
// ignore_for_file: invalid_use_of_protected_member
extension _NotificationsInboxPreferences on _NotificationsScreenState {
  Future<void> _loadPreferences() async {
    setState(() => _isPreferencesLoading = true);
    try {
      final prefs = await ref
          .read(notificationsRepositoryProvider)
          .getPreferences();
      if (!mounted) return;
      setState(() {
        _preferenceByType = preferenceMapFromList(prefs);
      });
      _notificationPrefsSheetInvalidate?.call();
    } catch (_) {
      if (!mounted) return;
      AppSnack.show(
        context,
        message: context.l10n.notificationsPrefsLoadFailed,
        type: AppSnackType.warning,
      );
    } finally {
      if (mounted) {
        setState(() => _isPreferencesLoading = false);
        _notificationPrefsSheetInvalidate?.call();
      }
    }
  }

  void _showSnoozePicker(NotificationPreferenceGroup group) {
    final List<_SnoozeDuration> options = <_SnoozeDuration>[
      _SnoozeDuration(
        context.l10n.notificationsSnooze1h,
        const Duration(hours: 1),
      ),
      _SnoozeDuration(
        context.l10n.notificationsSnooze4h,
        const Duration(hours: 4),
      ),
      _SnoozeDuration(
        context.l10n.notificationsSnooze8h,
        const Duration(hours: 8),
      ),
      _SnoozeDuration(
        context.l10n.notificationsSnooze24h,
        const Duration(hours: 24),
      ),
      _SnoozeDuration(
        context.l10n.notificationsSnooze1w,
        const Duration(days: 7),
      ),
      _SnoozeDuration(context.l10n.notificationsSnoozePermanent, null),
    ];
    showModalBottomSheet<_SnoozeDuration>(
      context: context,
      backgroundColor: AppColors.panelBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radius18),
        ),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Text(
                  context.l10n.notificationsSnoozeTitle,
                  style: Theme.of(
                    ctx,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              for (final _SnoozeDuration opt in options)
                ListTile(
                  title: Text(opt.label),
                  onTap: () => Navigator.of(ctx).pop(opt),
                ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    ).then((_SnoozeDuration? choice) {
      if (choice == null) return;
      final DateTime? mutedUntil = choice.duration != null
          ? DateTime.now().add(choice.duration!)
          : null;
      _snoozeGroupPreference(group, mutedUntil);
    });
  }

  Future<void> _snoozeGroupPreference(
    NotificationPreferenceGroup group,
    DateTime? mutedUntil,
  ) async {
    final Map<UserNotificationType, NotificationPreference> previous =
        Map<UserNotificationType, NotificationPreference>.from(
          _preferenceByType,
        );
    setState(() {
      _preferenceByType = applyGroupMuteToMap(
        _preferenceByType,
        group,
        muted: true,
        mutedUntil: mutedUntil,
      );
    });
    _notificationPrefsSheetInvalidate?.call();
    try {
      final List<NotificationPreference> updated =
          await Future.wait<NotificationPreference>(
            group.types.map(
              (UserNotificationType type) => ref
                  .read(notificationsRepositoryProvider)
                  .setPreference(
                    type: type,
                    muted: true,
                    mutedUntil: mutedUntil,
                  ),
            ),
          );
      if (!mounted) return;
      setState(() {
        for (final NotificationPreference pref in updated) {
          _preferenceByType[pref.type] = pref;
        }
      });
      _notificationPrefsSheetInvalidate?.call();
    } catch (_) {
      if (!mounted) return;
      setState(() => _preferenceByType = previous);
      _notificationPrefsSheetInvalidate?.call();
      AppSnack.show(
        context,
        message: context.l10n.notificationsPreferenceUpdateFailed,
        type: AppSnackType.warning,
      );
    }
  }

  Future<void> _toggleGroupPreference(
    NotificationPreferenceGroup group,
    bool enabled,
  ) async {
    final bool muted = !enabled;
    final Map<UserNotificationType, NotificationPreference> previous =
        Map<UserNotificationType, NotificationPreference>.from(
          _preferenceByType,
        );
    setState(() {
      _preferenceByType = applyGroupMuteToMap(
        _preferenceByType,
        group,
        muted: muted,
        mutedUntil: null,
      );
    });
    _notificationPrefsSheetInvalidate?.call();
    try {
      final List<NotificationPreference> updated =
          await Future.wait<NotificationPreference>(
            group.types.map(
              (UserNotificationType type) => ref
                  .read(notificationsRepositoryProvider)
                  .setPreference(type: type, muted: muted),
            ),
          );
      if (!mounted) return;
      setState(() {
        for (final NotificationPreference pref in updated) {
          _preferenceByType[pref.type] = pref;
        }
      });
      _notificationPrefsSheetInvalidate?.call();
    } catch (_) {
      if (!mounted) return;
      setState(() => _preferenceByType = previous);
      _notificationPrefsSheetInvalidate?.call();
      AppSnack.show(
        context,
        message: context.l10n.notificationsPreferenceUpdateFailed,
        type: AppSnackType.warning,
      );
    }
  }

  void _openPreferencesSheet() {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        useSafeArea: false,
        backgroundColor: AppColors.transparent,
        builder: (sheetContext) {
          return StatefulBuilder(
            builder:
                (
                  BuildContext context,
                  void Function(void Function()) setModalState,
                ) {
                  _notificationPrefsSheetInvalidate = () =>
                      setModalState(() {});
                  return ReportSheetScaffold(
                    fitToContent: true,
                    addBottomInset: true,
                    title: context.l10n.notificationsPrefsSheetTitle,
                    subtitle: context.l10n.notificationsPrefsSheetSubtitle,
                    trailing: ReportCircleIconButton(
                      icon: Icons.close_rounded,
                      semanticLabel: context.l10n.semanticClose,
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                      },
                    ),
                    child: _isPreferencesLoading
                        ? const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: AppSpacing.xl,
                            ),
                            child: Center(child: AppLoadingIndicator()),
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              for (final NotificationPreferenceGroup group
                                  in kNotificationPreferenceGroups)
                                GestureDetector(
                                  onLongPress: () {
                                    _showSnoozePicker(group);
                                  },
                                  child: SwitchListTile.adaptive(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      notificationPreferenceGroupTitle(
                                        context.l10n,
                                        group.id,
                                      ),
                                    ),
                                    subtitle: Text(
                                      notificationPreferenceGroupSubtitle(
                                        context.l10n,
                                        group,
                                        _preferenceByType,
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.textMuted,
                                          ),
                                    ),
                                    value: isNotificationPreferenceGroupEnabled(
                                      group,
                                      _preferenceByType,
                                    ),
                                    onChanged: (bool enabled) =>
                                        _toggleGroupPreference(group, enabled),
                                  ),
                                ),
                            ],
                          ),
                  );
                },
          );
        },
      ).whenComplete(() {
        _notificationPrefsSheetInvalidate = null;
      }),
    );
  }
}
