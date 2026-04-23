import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/network/connectivity_gate.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/data/event_offline_work_coordinator.dart';
import 'package:chisto_mobile/features/events/data/field_mode_queue.dart';
import 'package:chisto_mobile/features/events/data/field_mode_sync_service.dart';
import 'package:chisto_mobile/features/events/presentation/events_typography.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/shared/widgets/app_back_button.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';

/// Compact screen to inspect the offline field queue and push it to the API.
class FieldModeScreen extends StatefulWidget {
  const FieldModeScreen({super.key});

  @override
  State<FieldModeScreen> createState() => _FieldModeScreenState();
}

class _FieldModeScreenState extends State<FieldModeScreen>
    with WidgetsBindingObserver {
  List<Map<String, Object?>> _rows = const <Map<String, Object?>>[];
  bool _loading = true;
  bool _syncing = false;

  /// SQLite row id → last server error code from a partial field-batch response.
  final Map<int, String> _rowErrorByDbId = <int, String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_reload(scheduleAutoSyncAfter: true));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      unawaited(_reload(scheduleAutoSyncAfter: true));
    }
  }

  Future<void> _reload({bool scheduleAutoSyncAfter = false}) async {
    setState(() => _loading = true);
    final List<Map<String, Object?>> rows = await FieldModeQueue.instance
        .pendingRows();
    if (!mounted) {
      return;
    }
    setState(() {
      _rows = rows;
      _loading = false;
    });
    if (scheduleAutoSyncAfter && rows.isNotEmpty) {
      _scheduleOnlineAutoSync();
    }
    if (ServiceLocator.instance.isInitialized) {
      unawaited(EventOfflineWorkCoordinator.instance.refreshSnapshot());
    }
  }

  void _scheduleOnlineAutoSync() {
    unawaited(() async {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted || _syncing || _rows.isEmpty) {
        return;
      }
      final List<ConnectivityResult> connectivity =
          await ConnectivityGate.check();
      if (!ConnectivityGate.isOnline(connectivity)) {
        return;
      }
      await _syncNow();
    }());
  }

  String _operationSummary(String? opRaw) {
    final AppLocalizations l10n = context.l10n;
    if (opRaw == null || opRaw.isEmpty) {
      return l10n.eventsFieldModeRowUnknown;
    }
    try {
      final Object? decoded = jsonDecode(opRaw);
      if (decoded is Map<String, dynamic>) {
        final String? type = decoded['type'] as String?;
        if (type == 'live_impact_bags') {
          final Object? n = decoded['reportedBagsCollected'];
          final int count = n is int
              ? n
              : n is num
              ? n.toInt()
              : int.tryParse('$n') ?? 0;
          return l10n.eventsFieldModeRowLiveImpactBags(count);
        }
      }
    } on Object {
      // fall through
    }
    return l10n.eventsFieldModeRowUnknown;
  }

  Future<void> _syncNow() async {
    if (_rows.isEmpty || _syncing) {
      return;
    }
    final List<Map<String, Object?>> rowsBefore =
        List<Map<String, Object?>>.from(_rows);
    setState(() => _syncing = true);
    try {
      final FieldModeSyncService sync = FieldModeSyncService(
        client: ServiceLocator.instance.apiClient,
      );
      final FieldModeSyncResult result = await sync.syncPendingRows();
      if (!mounted) {
        return;
      }
      final FieldModeBatchBuildResult built = buildFieldBatchFromQueueRows(
        rowsBefore,
      );
      final Map<int, String> nextErrors = <int, String>{};
      for (int i = 0; i < result.errorCodesByOperationIndex.length; i++) {
        final String c = result.errorCodesByOperationIndex[i];
        if (c.isEmpty) {
          continue;
        }
        if (i < built.rowIdsInOpOrder.length) {
          final int? id = built.rowIdsInOpOrder[i];
          if (id != null) {
            nextErrors[id] = c;
          }
        }
      }
      setState(() {
        if (result.httpOk && result.failed == 0) {
          _rowErrorByDbId.clear();
        } else {
          _rowErrorByDbId
            ..clear()
            ..addAll(nextErrors);
        }
      });
      if (!result.hadOperations) {
        return;
      }
      if (!result.httpOk) {
        AppSnack.show(
          context,
          message: context.l10n.eventsFieldModeSyncFailed,
          type: AppSnackType.error,
        );
        return;
      }
      if (result.failed > 0 && result.applied > 0) {
        AppSnack.show(
          context,
          message: context.l10n.eventsFieldModeSyncPartial(
            result.applied,
            result.failed,
          ),
          type: AppSnackType.warning,
        );
      } else if (result.failed > 0) {
        AppSnack.show(
          context,
          message: context.l10n.eventsFieldModeSyncFailed,
          type: AppSnackType.error,
        );
      } else {
        AppSnack.show(
          context,
          message: context.l10n.eventsFieldModeSynced,
          type: AppSnackType.success,
        );
      }
      await _reload();
    } on Object {
      if (mounted) {
        AppSnack.show(
          context,
          message: context.l10n.eventsFieldModeSyncFailed,
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
    final double bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Row(
                children: <Widget>[
                  const AppBackButton(),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      context.l10n.eventsFieldModeTitle,
                      style: AppTypography.eventsDetailHeadline(textTheme),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!_loading && _rows.isNotEmpty)
                    TextButton(
                      onPressed: _syncing ? null : _syncNow,
                      child: _syncing
                          ? const CupertinoActivityIndicator()
                          : Text(
                              context.l10n.eventsFieldModeSync,
                              style: AppTypography.eventsTextLinkEmphasis(
                                textTheme,
                              ),
                            ),
                    ),
                ],
              ),
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: AppColors.divider.withValues(alpha: 0.75),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CupertinoActivityIndicator())
                  : _rows.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Text(
                          context.l10n.eventsFieldModeEmpty,
                          textAlign: TextAlign.center,
                          style: AppTypography.eventsBodyMuted(textTheme),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.only(
                        bottom: bottomPad + AppSpacing.md,
                      ),
                      itemCount: _rows.length,
                      itemBuilder: (BuildContext context, int i) {
                        final Map<String, Object?> row = _rows[i];
                        final String? opRaw = row['op'] as String?;
                        final String title = _operationSummary(opRaw);
                        final String created = '${row['createdAt'] ?? ''}';
                        final String statusLabel = _syncing
                            ? context.l10n.eventsFieldModeRowStatusSyncing
                            : context.l10n.eventsFieldModeRowStatusPending;
                        final int? rowId = row['id'] as int?;
                        final String? errCode = rowId != null
                            ? _rowErrorByDbId[rowId]
                            : null;
                        final String subtitleText =
                            errCode != null && errCode.isNotEmpty
                            ? '$created\n$statusLabel\n${context.l10n.eventsFieldModeRowServerError(errCode)}'
                            : '$created\n$statusLabel';
                        return Semantics(
                          label: '$title, $created, $statusLabel',
                          child: ListTile(
                            title: Text(
                              title,
                              style: AppTypography.eventsBodyProse(textTheme),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              subtitleText,
                              style: AppTypography.eventsBodyMuted(textTheme),
                            ),
                            isThreeLine: true,
                            trailing: _syncing
                                ? const CupertinoActivityIndicator()
                                : Icon(
                                    Icons.cloud_upload_outlined,
                                    color: AppColors.textMuted,
                                  ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
