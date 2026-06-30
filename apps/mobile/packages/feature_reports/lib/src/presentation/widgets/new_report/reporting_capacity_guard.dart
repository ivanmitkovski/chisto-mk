import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_reports/src/domain/models/report_capacity.dart';
import 'package:feature_reports/src/presentation/widgets/new_report/report_capacity_retry_duration.dart';
import 'package:feature_reports/src/presentation/widgets/new_report/reporting_cooldown_dialog.dart';
import 'package:flutter/material.dart';

Future<bool> showReportingCooldownDialog(
  BuildContext context,
  ReportCapacity capacity,
) async {
  final AppLocalizations l10n = context.l10n;
  final String retry = formatReportCapacityRetryDuration(
    l10n,
    capacity.retryAfterSeconds,
  );
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: AppColors.overlay,
    builder: (BuildContext dialogContext) =>
        ReportingCooldownDialog(retryDurationText: retry),
  );
  return false;
}
