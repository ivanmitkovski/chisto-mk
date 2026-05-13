import 'dart:io';

import 'package:chisto_mobile/features/reports/data/outbox/report_draft_photo_store.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_draft_repository.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_database.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_entry.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_repository.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
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

  test('loadDraft save clear summary with prune of missing file', () async {
    final Directory tmp = await Directory.systemTemp.createTemp('draft_repo_');
    final Database db = await _openTestDbIn(tmp, 'r.db');
    final ReportOutboxRepository outbox = SqfliteReportOutboxRepository(db);
    final ReportDraftPhotoStore photoStore = ReportDraftPhotoStore(
      rootOverride: Directory(p.join(tmp.path, 'media')),
    );
    final ReportDraftRepository repo = ReportDraftRepository(
      outbox: outbox,
      photoStore: photoStore,
    );

    final ReportDraftSummary empty = await repo.summary();
    expect(empty.hasDraft, isFalse);

    final File src = File(p.join(tmp.path, 'a.jpg'));
    await src.writeAsBytes(<int>[9, 9, 9]);
    final XFile managed = await repo.registerPhoto(XFile(src.path));

    await repo.save(
      draft: ReportDraft(photos: <XFile>[managed], title: 'River'),
      title: 'River',
      description: 'x',
      currentStageName: 'details',
      attemptedStageNames: <String>['evidence'],
      lastPersistedAtMs: 555,
    );

    final ReportDraftSummary s = await repo.summary();
    expect(s.hasDraft, isTrue);
    expect(s.photoCount, 1);
    expect(s.titlePreview, 'River');

    final ReportDraftLoadResult loaded = await repo.loadDraft();
    expect(loaded.kind, ReportDraftRestoreKind.restored);
    expect(loaded.hasDraft, isTrue);
    expect(loaded.restore?.currentStageName, 'details');
    expect(loaded.restore?.attemptedStageNames, <String>['evidence']);

    final String absPhoto = await photoStore.absolutePath(
      loaded.restore!.draft.photos.single.path,
    );
    await File(absPhoto).delete();
    final ReportDraftLoadResult pruned = await repo.loadDraft();
    expect(pruned.prunedPhotoCount, 1);
    expect(pruned.restore?.draft.photos, isEmpty);

    await repo.clear();
    final ReportDraftLoadResult after = await repo.loadDraft();
    expect(after.hasDraft, isFalse);

    await db.close();
    await tmp.delete(recursive: true);
  });

  test('isReportWizardDraftEntryResumable respects stage metadata', () {
    final ReportOutboxEntry emptyStage = ReportOutboxEntry(
      id: 'x',
      idempotencyKey: 'ix',
      draft: ReportDraft(),
      title: '',
      description: '',
      submitRequested: false,
      state: ReportOutboxState.pending,
      attemptCount: 0,
      createdAtMs: 1,
      updatedAtMs: 1,
      currentStageName: 'evidence',
    );
    expect(isReportWizardDraftEntryResumable(emptyStage), isFalse);

    final ReportOutboxEntry onDetails = emptyStage.copyWith(
      currentStageName: 'details',
    );
    expect(isReportWizardDraftEntryResumable(onDetails), isTrue);
  });
}
