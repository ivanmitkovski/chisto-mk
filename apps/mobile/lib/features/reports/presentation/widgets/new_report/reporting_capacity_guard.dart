import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_capacity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

String _formatRetry(int? retryAfterSeconds) {
  if (retryAfterSeconds == null || retryAfterSeconds <= 0) {
    return 'soon';
  }
  final int hours = retryAfterSeconds ~/ 3600;
  final int minutes = (retryAfterSeconds % 3600) ~/ 60;
  if (hours > 0) {
    return '${hours}h ${minutes}m';
  }
  if (minutes > 0) {
    return '${minutes}m';
  }
  return '${retryAfterSeconds}s';
}

Future<bool> showReportingCooldownDialog(
  BuildContext context,
  ReportCapacity capacity,
) async {
  final String retry = _formatRetry(capacity.retryAfterSeconds);
  await showCupertinoDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) => CupertinoAlertDialog(
      title: const Text('Reporting cooldown'),
      content: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          'You have used all 10 report credits and the emergency allowance.\n\n'
          'Emergency unlock retries in $retry.\n\n'
          '${capacity.unlockHint}',
          style: AppTypography.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ),
      actions: <CupertinoDialogAction>[
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Got it'),
        ),
      ],
    ),
  );
  return false;
}

