import 'dart:io';

import 'package:chisto_mobile/features/reports/data/outbox/report_draft_photo_store.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_draft_repository.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_database.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_repository.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../../shared/widget_test_bootstrap.dart';

Future<Database> _openTestDbIn(Directory parent, String fileName) {
  final String path = p.join(parent.path, fileName);
  return openDatabase(
    path,
    version: 3,
    onCreate: (Database db, int v) async {
      await db.execute('''
CREATE TABLE ${ReportOutboxDatabase.tableOutbox} (
  id TEXT NOT NULL PRIMARY KEY,
  idempotency_key TEXT NOT NULL UNIQUE,
  draft_json TEXT NOT NULL,
  state TEXT NOT NULL,
  submit_requested INTEGER NOT NULL DEFAULT 0,
  media_urls_json TEXT,
  attempt_count INTEGER NOT NULL DEFAULT 0,
  last_error_code TEXT,
  last_error_message TEXT,
  cooldown_until_ms INTEGER,
  report_id TEXT,
  created_at_ms INTEGER NOT NULL,
  updated_at_ms INTEGER NOT NULL,
  current_stage TEXT,
  attempted_stages_json TEXT,
  last_persisted_at_ms INTEGER
)''');
      await db.execute(
        'CREATE INDEX idx_report_outbox_state ON ${ReportOutboxDatabase.tableOutbox} (state, updated_at_ms)',
      );
    },
    onUpgrade: (Database db, int oldVersion, int newVersion) async {
      if (oldVersion < 2) {
        await db.execute(
          'ALTER TABLE ${ReportOutboxDatabase.tableOutbox} ADD COLUMN submit_requested INTEGER NOT NULL DEFAULT 1',
        );
      }
      if (oldVersion < 3) {
        await db.execute(
          'ALTER TABLE ${ReportOutboxDatabase.tableOutbox} ADD COLUMN current_stage TEXT',
        );
        await db.execute(
          'ALTER TABLE ${ReportOutboxDatabase.tableOutbox} ADD COLUMN attempted_stages_json TEXT',
        );
        await db.execute(
          'ALTER TABLE ${ReportOutboxDatabase.tableOutbox} ADD COLUMN last_persisted_at_ms INTEGER',
        );
      }
    },
  );
}

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  test('summaryListenable updates on save and clear; coalesces identical summary', () async {
    final Directory tmp = await Directory.systemTemp.createTemp('draft_sum_');
    final Database db = await _openTestDbIn(tmp, 's.db');
    final ReportOutboxRepository outbox = SqfliteReportOutboxRepository(db);
    final ReportDraftPhotoStore photoStore = ReportDraftPhotoStore(
      rootOverride: Directory(p.join(tmp.path, 'media')),
    );
    final ReportDraftRepository repo = ReportDraftRepository(
      outbox: outbox,
      photoStore: photoStore,
    );

    int notifications = 0;
    void onNotify() {
      notifications++;
    }

    repo.summaryListenable.addListener(onNotify);
    expect(repo.summaryListenable.value.hasDraft, isFalse);

    await repo.save(
      draft: ReportDraft(title: 'x'),
      title: 'x',
      description: '',
      lastPersistedAtMs: 1,
    );
    expect(repo.summaryListenable.value.hasDraft, isTrue);
    expect(repo.summaryListenable.value.titlePreview, 'x');
    expect(notifications, greaterThan(0));
    final int afterFirstSave = notifications;

    await repo.save(
      draft: ReportDraft(title: 'x'),
      title: 'x',
      description: '',
      lastPersistedAtMs: 1,
    );
    expect(notifications, afterFirstSave);

    await repo.clear();
    expect(repo.summaryListenable.value.hasDraft, isFalse);
    expect(notifications, greaterThan(afterFirstSave));

    await repo.hydrate();
    repo.summaryListenable.removeListener(onNotify);

    await db.close();
    await tmp.delete(recursive: true);
  });
}
