import 'dart:async';

import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_snack.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/app_surface/report_surface_aliases.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_events/src/data/chat/outbox/chat_outbox_store.dart';
import 'package:feature_events/src/data/event_offline_work_coordinator.dart';
import 'package:feature_events/src/presentation/navigation/events_navigation.dart';
import 'package:feature_events/src/presentation/screens/field_mode_screen.dart';
import 'package:feature_events/src/presentation/widgets/events_modal_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showOfflineWorkHubSheet(BuildContext context) {
  return showEventsSurfaceModal<void>(
    context: context,
    builder: (BuildContext ctx) => const _OfflineWorkHubBody(),
  );
}

class _OfflineWorkHubBody extends ConsumerStatefulWidget {
  const _OfflineWorkHubBody();

  @override
  ConsumerState<_OfflineWorkHubBody> createState() =>
      _OfflineWorkHubBodyState();
}

class _OfflineWorkHubBodyState extends ConsumerState<_OfflineWorkHubBody> {
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
                      child: AppButton.outlined(
                        label: context.l10n.eventsOfflineWorkRetryFailedChat,
                        onPressed: () => unawaited(_retryFailedChatOutbox()),
                        enabled:
                            !_syncing &&
                            ref.read(appBootstrapProvider).isInitialized,
                        expand: true,
                      ),
                    ),
                  ),
                PrimaryButton(
                  label: context.l10n.eventsOfflineWorkSyncNow,
                  isLoading: _syncing,
                  enabled: ref.read(appBootstrapProvider).isInitialized,
                  onPressed: ref.read(appBootstrapProvider).isInitialized
                      ? () => unawaited(_onSyncNow())
                      : null,
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
                    context.l10n.eventsOfflineWorkCountPending(
                      snap.checkInPending,
                    ),
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
                    context.l10n.eventsOfflineWorkCountPending(
                      snap.fieldPending,
                    ),
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
                        context.l10n.eventsOfflineWorkCountPending(
                          snap.chatPending,
                        ),
                        style: AppTypography.eventsBodyMuted(textTheme),
                      ),
                      if (snap.chatFailed > 0)
                        Text(
                          context.l10n.eventsOfflineWorkCountFailed(
                            snap.chatFailed,
                          ),
                          style: AppTypography.eventsBodyMuted(
                            textTheme,
                          ).copyWith(color: AppColors.accentWarning),
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
                    final List<String> ids = await ChatOutboxStore.shared
                        .listDistinctEventIdsWithWork();
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
                    await EventsNavigation.openDetail(
                      context,
                      eventId: ids.first,
                    );
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
