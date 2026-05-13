import 'dart:async';
import 'dart:io';

import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/network/connectivity_gate.dart';
import 'package:chisto_mobile/core/network/request_cancellation.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_constants.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_coordinator.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_entry.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_pipeline_phase.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_repository.dart';
import 'package:chisto_mobile/features/reports/domain/draft/report_idempotency_key.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_capacity.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_detail.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_submit_result.dart';
import 'package:chisto_mobile/features/reports/domain/models/reports_list_response.dart';
import 'package:chisto_mobile/features/reports/domain/repositories/reports_api_repository.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/widget_test_bootstrap.dart';

class _FakeOutboxRepo implements ReportOutboxRepository {
  final Map<String, ReportOutboxEntry> _rows = <String, ReportOutboxEntry>{};

  @override
  Future<int> countAllRows() async => _rows.length;

  @override
  Future<int> countSubmitPipeline() async {
    int n = 0;
    for (final ReportOutboxEntry e in _rows.values) {
      if (e.state == ReportOutboxState.uploading ||
          e.state == ReportOutboxState.submitting ||
          e.state == ReportOutboxState.cooldown) {
        n++;
      } else if (e.state == ReportOutboxState.pending && e.submitRequested) {
        n++;
      }
    }
    return n;
  }

  @override
  Future<void> delete(String id) async {
    _rows.remove(id);
  }

  @override
  Future<ReportOutboxEntry?> getById(String id) async => _rows[id];

  @override
  Future<ReportOutboxEntry?> getNextProcessable() async {
    final int now = DateTime.now().millisecondsSinceEpoch;
    final List<ReportOutboxEntry> candidates = _rows.values.where((ReportOutboxEntry e) {
      if (!<ReportOutboxState>{
        ReportOutboxState.pending,
        ReportOutboxState.uploading,
        ReportOutboxState.submitting,
        ReportOutboxState.cooldown,
      }.contains(e.state)) {
        return false;
      }
      if (e.cooldownUntilMs != null && e.cooldownUntilMs! > now) {
        return false;
      }
      if (e.state == ReportOutboxState.pending && !e.submitRequested) {
        return false;
      }
      return true;
    }).toList();
    if (candidates.isEmpty) return null;
    candidates.sort(
      (ReportOutboxEntry a, ReportOutboxEntry b) =>
          a.createdAtMs.compareTo(b.createdAtMs),
    );
    return candidates.first;
  }

  @override
  Future<ReportOutboxEntry?> getWizardDraftEntry() async =>
      getById(kReportWizardDraftRowId);

  @override
  Future<void> insert(ReportOutboxEntry entry) async {
    _rows[entry.id] = entry;
  }

  @override
  Future<void> update(ReportOutboxEntry entry) async {
    _rows[entry.id] = entry;
  }

  @override
  Future<void> saveWizardDraft({
    required ReportDraft draft,
    required String title,
    required String description,
    String? currentStageName,
    List<String>? attemptedStageNames,
    int? lastPersistedAtMs,
  }) async {
    final int now = DateTime.now().millisecondsSinceEpoch;
    final ReportOutboxEntry? existing = await getById(kReportWizardDraftRowId);
    if (existing == null) {
      await insert(
        ReportOutboxEntry(
          id: kReportWizardDraftRowId,
          idempotencyKey: 'idem_$kReportWizardDraftRowId',
          draft: draft,
          title: title.trim(),
          description: description.trim(),
          submitRequested: false,
          state: ReportOutboxState.pending,
          attemptCount: 0,
          createdAtMs: now,
        updatedAtMs: now,
        currentStageName: currentStageName,
        attemptedStageNames: attemptedStageNames ?? const <String>[],
        lastPersistedAtMs: lastPersistedAtMs,
      ),
    );
    return;
  }
  await update(
    existing.copyWith(
      draft: draft,
      title: title.trim(),
      description: description.trim(),
      submitRequested: false,
      state: ReportOutboxState.pending,
      clearMediaUrls: true,
      clearLastError: true,
      clearCooldownUntil: true,
      updatedAtMs: now,
      currentStageName: currentStageName ?? existing.currentStageName,
      attemptedStageNames: attemptedStageNames ?? existing.attemptedStageNames,
      lastPersistedAtMs: lastPersistedAtMs ?? existing.lastPersistedAtMs,
    ),
  );
}
}

class _StubApi implements ReportsApiRepository {
  _StubApi({
    this.onSubmit,
    this.onUpload,
  });

  final Future<ReportSubmitResult> Function({
    required double latitude,
    required double longitude,
    required String title,
    String? description,
    List<String>? mediaUrls,
    String? category,
    int? severity,
    String? address,
    String? cleanupEffort,
    String? idempotencyKey,
  })?
  onSubmit;

  final Future<List<String>> Function(List<String> paths)? onUpload;

  final List<String?> recordedIdempotencyKeys = <String?>[];

  @override
  Future<ReportCapacity> getReportingCapacity() async {
    return const ReportCapacity(
      creditsAvailable: 1,
      emergencyAvailable: true,
      emergencyWindowDays: 7,
      retryAfterSeconds: null,
      nextEmergencyReportAvailableAt: null,
      unlockHint: '',
    );
  }

  @override
  Future<ReportDetail> getReportById(
    String id, {
    RequestCancellationToken? cancellation,
  }) async => throw UnimplementedError();

  @override
  Future<ReportsListResponse> getMyReports({
    int page = 1,
    int limit = 20,
    RequestCancellationToken? cancellation,
  }) async => throw UnimplementedError();

  @override
  Future<ReportSubmitResult> submitReport({
    required double latitude,
    required double longitude,
    required String title,
    String? description,
    List<String>? mediaUrls,
    String? category,
    int? severity,
    String? address,
    String? cleanupEffort,
    String? idempotencyKey,
  }) async {
    recordedIdempotencyKeys.add(idempotencyKey);
    if (onSubmit != null) {
      return onSubmit!(
        latitude: latitude,
        longitude: longitude,
        title: title,
        description: description,
        mediaUrls: mediaUrls,
        category: category,
        severity: severity,
        address: address,
        cleanupEffort: cleanupEffort,
        idempotencyKey: idempotencyKey,
      );
    }
    return ReportSubmitResult(
      reportId: 'r1',
      reportNumber: 'R-1',
      siteId: 's1',
      isNewSite: false,
      pointsAwarded: 0,
    );
  }

  @override
  Future<void> uploadReportMedia(String reportId, List<String> filePaths) async {}

  @override
  Future<List<String>> uploadPhotos(List<String> filePaths) async {
    if (onUpload != null) return onUpload!(filePaths);
    return <String>[];
  }
}

ReportDraft _validDraft() {
  return ReportDraft(
    category: ReportCategory.other,
    title: 'Title',
    description: 'Desc',
    latitude: 41.99,
    longitude: 21.43,
    address: 'Skopje',
  );
}

Future<List<ConnectivityResult>> Function()? _savedCheck;
Stream<List<ConnectivityResult>> Function()? _savedWatch;

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  setUp(() {
    _savedCheck = ConnectivityGate.check;
    _savedWatch = ConnectivityGate.watch;
  });

  tearDown(() async {
    ConnectivityGate.check = _savedCheck!;
    ConnectivityGate.watch = _savedWatch!;
  });

  group('ReportOutboxCoordinator', () {
    test('happy path empty photos emits success with same outboxId', () async {
      final _FakeOutboxRepo repo = _FakeOutboxRepo();
      final _StubApi api = _StubApi();
      final ReportOutboxCoordinator c = ReportOutboxCoordinator(
        repository: repo,
        reportsApi: api,
      );
      await c.start();
      final Future<ReportOutboxSuccess> once = c.successStream.first;
      final Future<ReportSubmitResult> done = c.submitReportAndAwait(
        draft: _validDraft(),
        title: 'Title',
        description: 'Desc',
      );
      final ReportOutboxSuccess ev = await once;
      expect(ev.outboxId, kReportWizardDraftRowId);
      final ReportSubmitResult r = await done;
      expect(r.reportId, 'r1');
      await c.dispose();
    });

    test('offline gate does not call submit', () async {
      ConnectivityGate.check =
          () async => <ConnectivityResult>[ConnectivityResult.none];
      final _FakeOutboxRepo repo = _FakeOutboxRepo();
      final _StubApi api = _StubApi();
      final ReportOutboxCoordinator c = ReportOutboxCoordinator(
        repository: repo,
        reportsApi: api,
      );
      final Future<ReportOutboxEntry> active = c.activeEntryStream
          .where((ReportOutboxEntry? e) => e != null)
          .map((ReportOutboxEntry? e) => e!)
          .first;
      await c.start();
      await c.enqueueSubmit(
        draft: _validDraft(),
        title: 'Title',
        description: 'Desc',
      );
      final ReportOutboxEntry row = await active;
      expect(row.id, isNotEmpty);
      expect(api.recordedIdempotencyKeys, isEmpty);
      await Future<void>.delayed(const Duration(milliseconds: 400));
      await c.dispose();
    });

    test('pipelinePhaseStream emits offlineWait when offline after enqueue', () async {
      ConnectivityGate.check =
          () async => <ConnectivityResult>[ConnectivityResult.none];
      final _FakeOutboxRepo repo = _FakeOutboxRepo();
      final _StubApi api = _StubApi();
      final ReportOutboxCoordinator c = ReportOutboxCoordinator(
        repository: repo,
        reportsApi: api,
      );
      final List<ReportOutboxPipelinePhase> phases = <ReportOutboxPipelinePhase>[];
      final StreamSubscription<ReportOutboxPipelinePhase> sub = c.pipelinePhaseStream.listen(phases.add);
      await c.start();
      await c.enqueueSubmit(
        draft: _validDraft(),
        title: 'Title',
        description: 'Desc',
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(phases, contains(ReportOutboxPipelinePhase.offlineWait));
      await sub.cancel();
      await c.dispose();
    });

    test('cooldown stops pipeline on REPORTING_COOLDOWN', () async {
      final _FakeOutboxRepo repo = _FakeOutboxRepo();
      final _StubApi api = _StubApi(
        onSubmit: ({
          required double latitude,
          required double longitude,
          required String title,
          String? description,
          List<String>? mediaUrls,
          String? category,
          int? severity,
          String? address,
          String? cleanupEffort,
          String? idempotencyKey,
        }) async {
          throw AppError(
            code: 'REPORTING_COOLDOWN',
            message: 'wait',
            details: <String, dynamic>{
              'retryAfterSeconds': 120,
            },
          );
        },
      );
      final ReportOutboxCoordinator c = ReportOutboxCoordinator(
        repository: repo,
        reportsApi: api,
      );
      await c.start();
      await c.enqueueSubmit(
        draft: _validDraft(),
        title: 'Title',
        description: 'Desc',
      );
      await Future<void>.delayed(const Duration(milliseconds: 400));
      final ReportOutboxEntry? row = await repo.getById(kReportWizardDraftRowId);
      expect(row?.state, ReportOutboxState.cooldown);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await c.dispose();
    });

    test('same idempotencyKey across retries', () async {
      final _FakeOutboxRepo repo = _FakeOutboxRepo();
      final _StubApi api = _StubApi(
        onSubmit: ({
          required double latitude,
          required double longitude,
          required String title,
          String? description,
          List<String>? mediaUrls,
          String? category,
          int? severity,
          String? address,
          String? cleanupEffort,
          String? idempotencyKey,
        }) async {
          throw AppError.server();
        },
      );
      final ReportOutboxCoordinator c = ReportOutboxCoordinator(
        repository: repo,
        reportsApi: api,
      );
      await c.start();
      await c.enqueueSubmit(
        draft: _validDraft(),
        title: 'Title',
        description: 'Desc',
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await c.scheduleProcess();
      expect(api.recordedIdempotencyKeys.length, 1);
      await Future<void>.delayed(const Duration(seconds: 4));
      await c.scheduleProcess();
      expect(api.recordedIdempotencyKeys.length, 2);
      expect(api.recordedIdempotencyKeys.toSet().length, 1);
      await c.dispose();
    });

    test('enqueueSubmit rejects when pipeline already active', () async {
      final _FakeOutboxRepo repo = _FakeOutboxRepo();
      final int t = DateTime.now().millisecondsSinceEpoch;
      await repo.insert(
        ReportOutboxEntry(
          id: 'other',
          idempotencyKey: 'x',
          draft: _validDraft(),
          title: 't',
          description: '',
          submitRequested: true,
          state: ReportOutboxState.submitting,
          attemptCount: 0,
          createdAtMs: t,
          updatedAtMs: t,
        ),
      );
      final ReportOutboxCoordinator c = ReportOutboxCoordinator(
        repository: repo,
        reportsApi: _StubApi(),
      );
      expect(
        () => c.enqueueSubmit(
          draft: _validDraft(),
          title: 'a',
          description: 'b',
        ),
        throwsA(isA<StateError>()),
      );
      await c.dispose();
    });

    test('resetFailedToPending only mutates failed rows', () async {
      final _FakeOutboxRepo repo = _FakeOutboxRepo();
      final int t = DateTime.now().millisecondsSinceEpoch;
      await repo.insert(
        ReportOutboxEntry(
          id: 'f1',
          idempotencyKey: 'f',
          draft: _validDraft(),
          title: 't',
          description: '',
          submitRequested: true,
          state: ReportOutboxState.failed,
          attemptCount: 3,
          createdAtMs: t,
          updatedAtMs: t,
        ),
      );
      final ReportOutboxCoordinator c = ReportOutboxCoordinator(
        repository: repo,
        reportsApi: _StubApi(),
      );
      await c.resetFailedToPending('f1');
      expect((await repo.getById('f1'))?.state, ReportOutboxState.pending);
      await c.resetFailedToPending('missing');
      await Future<void>.delayed(const Duration(milliseconds: 600));
      await c.dispose();
    });

    test('resumes upload phase from persisted uploading state', () async {
      final _FakeOutboxRepo repo = _FakeOutboxRepo();
      final List<int> uploadBatchSizes = <int>[];
      final _StubApi api = _StubApi(
        onUpload: (List<String> paths) async {
          uploadBatchSizes.add(paths.length);
          return List<String>.generate(
            paths.length,
            (int i) => 'https://example.com/u$i.jpg',
          );
        },
      );
      final int t = DateTime.now().millisecondsSinceEpoch;
      final Directory temp =
          await Directory.systemTemp.createTemp('outbox_resume_upload_');
      addTearDown(() async {
        try {
          await temp.delete(recursive: true);
        } catch (_) {}
      });
      final File fake = File('${temp.path}/pic.jpg');
      await fake.writeAsBytes(<int>[0xFF, 0xD8, 0xFF, 0xD9]);
      final String idem = ReportIdempotencyKey.generate();
      await repo.insert(
        ReportOutboxEntry(
          id: kReportWizardDraftRowId,
          idempotencyKey: idem,
          draft: _validDraft().copyWith(
            photos: <XFile>[XFile(fake.path)],
          ),
          title: 'Title',
          description: 'Desc',
          submitRequested: true,
          state: ReportOutboxState.uploading,
          attemptCount: 0,
          createdAtMs: t,
          updatedAtMs: t,
        ),
      );
      final ReportOutboxCoordinator c = ReportOutboxCoordinator(
        repository: repo,
        reportsApi: api,
      );
      final Future<ReportOutboxSuccess> done = c.successStream.first;
      await c.start();
      final ReportOutboxSuccess ev =
          await done.timeout(const Duration(seconds: 20));
      expect(ev.outboxId, kReportWizardDraftRowId);
      expect(uploadBatchSizes, isNotEmpty);
      await c.dispose();
    });
  });
}
