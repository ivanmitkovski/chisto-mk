import 'dart:async';

import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/core/providers/reports_providers.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_reports/src/data/outbox/report_outbox_coordinator.dart';
import 'package:feature_reports/src/data/outbox/report_outbox_entry.dart';
import 'package:feature_reports/src/data/outbox/report_outbox_pipeline_phase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Outbox pipeline status for the reports list (queued / uploading / failed).
class ReportOutboxStatusBanner extends ConsumerStatefulWidget {
  const ReportOutboxStatusBanner({super.key});

  @override
  ConsumerState<ReportOutboxStatusBanner> createState() =>
      _ReportOutboxStatusBannerState();
}

class _ReportOutboxStatusBannerState
    extends ConsumerState<ReportOutboxStatusBanner> {
  ReportOutboxPipelinePhase _phase = ReportOutboxPipelinePhase.idle;
  ReportOutboxEntry? _active;
  ReportOutboxEntry? _lastFailed;
  StreamSubscription<ReportOutboxPipelinePhase>? _phaseSub;
  StreamSubscription<ReportOutboxEntry?>? _activeSub;

  @override
  void initState() {
    super.initState();
    final ReportOutboxCoordinator coordinator = ref.read(
      reportOutboxCoordinatorProvider,
    );
    _phaseSub = coordinator.pipelinePhaseStream.listen(_onPhase);
    _activeSub = coordinator.activeEntryStream.listen(_onActive);
  }

  void _onPhase(ReportOutboxPipelinePhase phase) {
    if (!mounted) return;
    setState(() => _phase = phase);
  }

  void _onActive(ReportOutboxEntry? entry) {
    if (!mounted) return;
    setState(() {
      _active = entry;
      if (entry != null &&
          entry.state == ReportOutboxState.failed &&
          entry.submitRequested) {
        _lastFailed = entry;
      } else if (entry != null &&
          entry.state != ReportOutboxState.failed &&
          entry.state != ReportOutboxState.cooldown) {
        _lastFailed = null;
      }
    });
  }

  @override
  void dispose() {
    unawaited(_phaseSub?.cancel());
    unawaited(_activeSub?.cancel());
    super.dispose();
  }

  Future<void> _retryFailed() async {
    final ReportOutboxEntry? failed = _lastFailed;
    if (failed == null) return;
    await ref
        .read(reportOutboxCoordinatorProvider)
        .resetFailedToPending(failed.id);
    if (!mounted) return;
    setState(() => _lastFailed = null);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final _OutboxUiStatus? status = _resolveStatus();
    if (status == null) {
      return const SizedBox.shrink();
    }

    final Color bg = switch (status.tone) {
      _OutboxUiTone.error => AppColors.error.withValues(alpha: 0.12),
      _OutboxUiTone.warning => AppColors.accentWarning.withValues(alpha: 0.14),
      _OutboxUiTone.info => AppColors.primary.withValues(alpha: 0.12),
    };
    final Color fg = switch (status.tone) {
      _OutboxUiTone.error => AppColors.error,
      _OutboxUiTone.warning => AppColors.accentWarning,
      _OutboxUiTone.info => AppColors.primary,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Material(
        color: bg,
        borderRadius: AppRadii.sm,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(status.icon, size: 18, color: fg),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      status.label(l10n),
                      maxLines: 4,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypographySurfaces.reportsOutboxBannerBody(
                        Theme.of(context).textTheme,
                      ),
                    ),
                  ),
                ],
              ),
              if (status.showRetry)
                Align(
                  alignment: Alignment.centerRight,
                  child: AppButton.text(
                    label: l10n.reportListOutboxFailedRetry,
                    onPressed: _retryFailed,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  _OutboxUiStatus? _resolveStatus() {
    final ReportOutboxEntry? entry = _active ?? _lastFailed;
    if (entry != null && entry.state == ReportOutboxState.failed) {
      return _OutboxUiStatus(
        tone: _OutboxUiTone.error,
        icon: Icons.error_outline_rounded,
        label: (AppLocalizations l10n) => l10n.reportListOutboxFailedBanner,
        showRetry: true,
      );
    }
    if (_phase == ReportOutboxPipelinePhase.offlineWait) {
      return _OutboxUiStatus(
        tone: _OutboxUiTone.warning,
        icon: Icons.cloud_off_outlined,
        label: (AppLocalizations l10n) => l10n.reportListOutboxOfflineBanner,
      );
    }
    if (_phase == ReportOutboxPipelinePhase.cooldownWait) {
      return _OutboxUiStatus(
        tone: _OutboxUiTone.warning,
        icon: Icons.schedule_rounded,
        label: (AppLocalizations l10n) => l10n.reportListOutboxCooldownBanner,
      );
    }
    if (_phase != ReportOutboxPipelinePhase.active || _active == null) {
      return null;
    }
    return switch (_active!.state) {
      ReportOutboxState.uploading => _OutboxUiStatus(
        tone: _OutboxUiTone.info,
        icon: Icons.cloud_upload_outlined,
        label: (AppLocalizations l10n) => l10n.reportListOutboxUploadingChip,
      ),
      ReportOutboxState.submitting => _OutboxUiStatus(
        tone: _OutboxUiTone.info,
        icon: Icons.send_outlined,
        label: (AppLocalizations l10n) => l10n.reportListOutboxSubmittingChip,
      ),
      ReportOutboxState.pending ||
      ReportOutboxState.cooldown => _OutboxUiStatus(
        tone: _OutboxUiTone.info,
        icon: Icons.hourglass_top_outlined,
        label: (AppLocalizations l10n) => l10n.reportListOutboxQueuedChip,
      ),
      ReportOutboxState.failed => _OutboxUiStatus(
        tone: _OutboxUiTone.error,
        icon: Icons.error_outline_rounded,
        label: (AppLocalizations l10n) => l10n.reportListOutboxFailedBanner,
        showRetry: true,
      ),
      ReportOutboxState.succeeded => null,
    };
  }
}

enum _OutboxUiTone { info, warning, error }

class _OutboxUiStatus {
  const _OutboxUiStatus({
    required this.tone,
    required this.icon,
    required this.label,
    this.showRetry = false,
  });

  final _OutboxUiTone tone;
  final IconData icon;
  final String Function(AppLocalizations l10n) label;
  final bool showRetry;
}

/// Compact chip variant for inline header use.
class ReportOutboxStatusChip extends StatelessWidget {
  const ReportOutboxStatusChip({super.key});

  @override
  Widget build(BuildContext context) {
    return const ReportOutboxStatusBanner();
  }
}
