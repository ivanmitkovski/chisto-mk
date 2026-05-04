import 'dart:io';

import 'package:chisto_mobile/features/reports/data/outbox/report_draft_photo_store.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_draft_repository.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_database.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_entry.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_repository.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:chisto_mobile/features/reports/presentation/controllers/new_report_controller.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/report_stage.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/resume_with_incoming_photo_dialog.dart';
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

  test('scheduleAutosave persists after debounce', () async {
    final Directory tmp = await Directory.systemTemp.createTemp('nr_ctrl_');
    final Database db = await _openTestDbIn(tmp, 'c.db');
    final ReportDraftRepository draftRepo = ReportDraftRepository(
      outbox: SqfliteReportOutboxRepository(db),
      photoStore: ReportDraftPhotoStore(
        rootOverride: Directory(p.join(tmp.path, 'ph')),
      ),
    );
    final NewReportController c = NewReportController(
      draftRepository: draftRepo,
    );
    c.updateTitle('deb');
    c.scheduleAutosave(titleText: 'deb', descriptionText: '');
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final ReportOutboxEntry? row =
        await SqfliteReportOutboxRepository(db).getWizardDraftEntry();
    expect(row?.title, 'deb');
    c.dispose();
    await db.close();
    await tmp.delete(recursive: true);
  });

  test('restoreSavedDraft restores stage and flush after removePhoto', () async {
    final Directory tmp = await Directory.systemTemp.createTemp('nr_ctrl2_');
    final Database db = await _openTestDbIn(tmp, 'c.db');
    final SqfliteReportOutboxRepository outbox = SqfliteReportOutboxRepository(db);
    final ReportDraftRepository draftRepo = ReportDraftRepository(
      outbox: outbox,
      photoStore: ReportDraftPhotoStore(
        rootOverride: Directory(p.join(tmp.path, 'ph')),
      ),
    );

    final File f1 = File(p.join(tmp.path, 'p1.jpg'))..writeAsBytes(<int>[1]);
    final File f2 = File(p.join(tmp.path, 'p2.jpg'))..writeAsBytes(<int>[2]);
    final NewReportController c = NewReportController(
      draftRepository: draftRepo,
    );
    await c.addPhoto(XFile(f1.path));
    await c.addPhoto(XFile(f2.path));
    c.goToStage(ReportStage.details, unfocusFirst: false);
    c.markStageAttempted(ReportStage.evidence);
    await c.flushPendingPersist(titleText: 't', descriptionText: '');
    c.dispose();

    final NewReportController c2 = NewReportController(
      draftRepository: draftRepo,
    );
    final ReportDraftLoadResult r = await c2.restoreSavedDraft();
    expect(r.kind, ReportDraftRestoreKind.restored);
    expect(c2.currentStage, ReportStage.details);

    await c2.removePhoto(0);
    await c2.flushPendingPersist(titleText: '', descriptionText: '');
    final ReportOutboxEntry? row = await outbox.getWizardDraftEntry();
    expect(row?.draft.photos.length, 1);

    await c2.discardDraft();
    final ReportDraftLoadResult cleared = await draftRepo.loadDraft();
    expect(cleared.hasDraft, isFalse);

    c2.dispose();
    await db.close();
    await tmp.delete(recursive: true);
  });

  test('initial photo is deferred until seedInitialPhotoFromPending', () async {
    final Directory tmp = await Directory.systemTemp.createTemp('nr_ctrl3_');
    final Database db = await _openTestDbIn(tmp, 'c.db');
    final ReportDraftRepository draftRepo = ReportDraftRepository(
      outbox: SqfliteReportOutboxRepository(db),
      photoStore: ReportDraftPhotoStore(
        rootOverride: Directory(p.join(tmp.path, 'ph')),
      ),
    );
    final File f = File(p.join(tmp.path, 'cam.jpg'))..writeAsBytes(<int>[9]);
    final NewReportController c = NewReportController(
      draftRepository: draftRepo,
      initialPhoto: XFile(f.path),
    );
    expect(c.draft.photos, isEmpty);
    await c.seedInitialPhotoFromPending();
    expect(c.draft.photos.length, 1);
    c.dispose();
    await db.close();
    await tmp.delete(recursive: true);
  });

  test('resolveIncomingPhotoMerge replace clears then seeds photo', () async {
    final Directory tmp = await Directory.systemTemp.createTemp('nr_ctrl4_');
    final Database db = await _openTestDbIn(tmp, 'c.db');
    final SqfliteReportOutboxRepository outbox = SqfliteReportOutboxRepository(db);
    final ReportDraftRepository draftRepo = ReportDraftRepository(
      outbox: outbox,
      photoStore: ReportDraftPhotoStore(
        rootOverride: Directory(p.join(tmp.path, 'ph')),
      ),
    );
    final NewReportController seed = NewReportController(draftRepository: draftRepo);
    seed.updateTitle('old');
    await seed.flushPendingPersist(titleText: 'old', descriptionText: '');
    seed.dispose();

    final File incoming = File(p.join(tmp.path, 'new.jpg'))..writeAsBytes(<int>[8]);
    final NewReportController c = NewReportController(
      draftRepository: draftRepo,
      initialPhoto: XFile(incoming.path),
    );
    await c.resolveIncomingPhotoMerge(ResumeWithIncomingChoice.replaceDraft);
    expect(c.draft.title, '');
    expect(c.draft.photos.length, 1);
    c.dispose();
    await db.close();
    await tmp.delete(recursive: true);
  });
}
