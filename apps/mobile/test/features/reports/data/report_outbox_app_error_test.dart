import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:feature_reports/src/data/outbox/report_outbox_app_error.dart';
import 'package:feature_reports/src/data/outbox/report_outbox_entry.dart';
import 'package:feature_reports/src/domain/models/report_draft.dart';
import 'package:flutter_test/flutter_test.dart';

ReportOutboxEntry _failedEntry({String? code, String? message}) {
  final int t = DateTime.now().millisecondsSinceEpoch;
  return ReportOutboxEntry(
    id: 'outbox-1',
    idempotencyKey: 'key',
    draft: ReportDraft(),
    title: 'Title',
    description: 'Desc',
    state: ReportOutboxState.failed,
    attemptCount: 1,
    lastErrorCode: code,
    lastErrorMessage: message,
    createdAtMs: t,
    updatedAtMs: t,
  );
}

void main() {
  test('maps network outbox code without exposing stored message', () {
    final AppError error = appErrorFromOutboxFailure(
      _failedEntry(
        code: 'NETWORK_ERROR',
        message: "Failed host lookup: 'api.chisto.mk'",
      ),
    );
    expect(error.code, 'NETWORK_ERROR');
    expect(error.message, isNot(contains('Failed host lookup')));
  });
}
