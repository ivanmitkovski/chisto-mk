import 'dart:async';

import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/data/chat/outbox/chat_outbox_store.dart';
import 'package:chisto_mobile/features/events/data/event_offline_work_coordinator.dart';
import 'package:chisto_mobile/features/events/presentation/events_typography.dart';
import 'package:chisto_mobile/features/events/presentation/navigation/events_navigation.dart';
import 'package:chisto_mobile/features/events/presentation/screens/field_mode_screen.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/events_modal_sheet.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:chisto_mobile/shared/widgets/primary_button.dart';

Future<void> showOfflineWorkHubSheet(BuildContext context) {
  return showEventsSurfaceModal<void>(
    context: context,
    builder: (BuildContext ctx) => const _OfflineWorkHubBody(),
  );
}

class _OfflineWorkHubBody extends StatefulWidget {
  const _OfflineWorkHubBody();

  @override
  State<_OfflineWorkHubBody> createState() => _OfflineWorkHubBodyState();
}

class _OfflineWorkHubBodyState extends State<_OfflineWorkHubBody> {
  bool _syncing = false;

  Future<void> _retryFailedChatOutbox() async {
    setState(() => _syncing = true);
    try {
      await ChatOutboxStore.shared.requeueAllFailedRows();
      await EventOfflineWorkCoordinator.instance.refreshSnapshot();
      await EventOfflineWorkCoordinator.instance.requestManualDrain();
      if (!mounted) {
        return;
      }
      AppSnack.show(
        context,
        message: context.l10n.eventsOfflineWorkSyncDone,
        type: AppSnackType.success,
      );
    } on Object {
      if (mounted) {
        AppSnack.show(
          context,
          message: context.l10n.eventsOfflineWorkDrainFailed,
          type: AppSnackType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _syncing = false);
      }
    }
  }

  Future<void> _onSyncNow() async {
    setState(() => _syncing = true);
    try {
      await EventOfflineWorkCoordinator.instance.requestManualDrain();
      if (!mounted) {
        return;
      }
      AppSnack.show(
        context,
        message: context.l10n.eventsOfflineWorkSyncDone,
        type: AppSnackType.success,
      );
    } on Object {
      if (mounted) {
        AppSnack.show(
          context,
          message: context.l10n.eventsOfflineWorkDrainFailed,
          type: AppSnackType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _syncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Semantics(
      label: context.l10n.eventsOfflineWorkHubSemanticSheet,
      container: true,
      child: ValueListenableBuilder<EventOfflineWorkSnapshot>(
        valueListenable: EventOfflineWorkCoordinator.instance.snapshot,
        builder: (BuildContext context, EventOfflineWorkSnapshot snap, _) {
          final String subtitle = snap.phase == OfflineWorkSyncPhase.syncing
              ? context.l10n.eventsOfflineWorkSyncing
              : snap.phase == OfflineWorkSyncPhase.failed
                  ? context.l10n.eventsOfflineWorkDrainFailed
                  : context.l10n.eventsOfflineWorkSubtitle;
          return ReportSheetScaffold(
            title: context.l10n.eventsOfflineWorkHubTitle,
            subtitle: subtitle,
            fitToContent: true,
            footer: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (snap.chatFailed > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Semantics(
                      button: true,
                      label: context.l10n.eventsOfflineWorkRetryFailedChat,
                      child: OutlinedButton(
                        onPressed: _syncing || !ServiceLocator.instance.isInitialized
                            ? null
                            : () => unawaited(_retryFailedChatOutbox()),
                        child: Text(context.l10n.eventsOfflineWorkRetryFailedChat),
                      ),
                    ),
                  ),
                PrimaryButton(
                  label: context.l10n.eventsOfflineWorkSyncNow,
                  isLoading: _syncing,
                  enabled: ServiceLocator.instance.isInitialized,
                  onPressed:
                      ServiceLocator.instance.isInitialized ? () => unawaited(_onSyncNow()) : null,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    context.l10n.eventsOfflineWorkSectionCheckIns,
                    style: AppTypography.eventsSectionTitle(textTheme),
                  ),
                  subtitle: Text(
                    context.l10n.eventsOfflineWorkCountPending(snap.checkInPending),
                    style: AppTypography.eventsBodyMuted(textTheme),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    context.l10n.eventsOfflineWorkSectionField,
                    style: AppTypography.eventsSectionTitle(textTheme),
                  ),
                  subtitle: Text(
                    context.l10n.eventsOfflineWorkCountPending(snap.fieldPending),
                    style: AppTypography.eventsBodyMuted(textTheme),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    context.l10n.eventsOfflineWorkSectionChat,
                    style: AppTypography.eventsSectionTitle(textTheme),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        context.l10n.eventsOfflineWorkCountPending(snap.chatPending),
                        style: AppTypography.eventsBodyMuted(textTheme),
                      ),
                      if (snap.chatFailed > 0)
                        Text(
                          context.l10n.eventsOfflineWorkCountFailed(snap.chatFailed),
                          style: AppTypography.eventsBodyMuted(textTheme).copyWith(
                            color: AppColors.accentWarning,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    context.l10n.eventsOfflineWorkOpenFieldQueue,
                    style: AppTypography.eventsSheetTextLink(textTheme),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const FieldModeScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    context.l10n.eventsOfflineWorkOpenChat,
                    style: AppTypography.eventsSheetTextLink(textTheme),
                  ),
                  onTap: () async {
                    Navigator.of(context).pop();
                    final List<String> ids =
                        await ChatOutboxStore.shared.listDistinctEventIdsWithWork();
                    if (!context.mounted) {
                      return;
                    }
                    if (ids.isEmpty) {
                      AppSnack.show(
                        context,
                        message: context.l10n.eventsOfflineWorkResolveInChat,
                        type: AppSnackType.info,
                      );
                      return;
                    }
                    await EventsNavigation.openDetail(context, eventId: ids.first);
                    if (context.mounted) {
                      AppSnack.show(
                        context,
                        message: context.l10n.eventsOfflineWorkResolveInChat,
                        type: AppSnackType.info,
                      );
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
