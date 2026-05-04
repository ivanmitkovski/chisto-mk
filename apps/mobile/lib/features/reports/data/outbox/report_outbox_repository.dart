import 'dart:convert';

import 'package:chisto_mobile/features/reports/data/outbox/report_draft_json_codec.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_constants.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_dao.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_database.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_entry.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';
import 'package:sqflite/sqflite.dart';

abstract class ReportOutboxRepository {
  Future<void> insert(ReportOutboxEntry entry);
  Future<void> update(ReportOutboxEntry entry);
  Future<ReportOutboxEntry?> getById(String id);
  Future<ReportOutboxEntry?> getNextProcessable();
  Future<ReportOutboxEntry?> getWizardDraftEntry();
  Future<int> countSubmitPipeline();
  Future<int> countAllRows();
  Future<void> saveWizardDraft({
    required ReportDraft draft,
    required String title,
    required String description,
    String? currentStageName,
    List<String>? attemptedStageNames,
    int? lastPersistedAtMs,
  });
  Future<void> delete(String id);
}

String _stateToDb(ReportOutboxState s) => s.name;

ReportOutboxState _stateFromDb(String raw) {
  return ReportOutboxState.values.firstWhere(
    (ReportOutboxState e) => e.name == raw,
    orElse: () => ReportOutboxState.pending,
  );
}

class SqfliteReportOutboxRepository implements ReportOutboxRepository {
  SqfliteReportOutboxRepository(Database db) : _dao = ReportOutboxDao(db);

  final ReportOutboxDao _dao;

  static Future<SqfliteReportOutboxRepository> open() async {
    final Database db = await ReportOutboxDatabase.open();
    return SqfliteReportOutboxRepository(db);
  }

  /// Missing or unknown `submit_requested` is treated as **not** requested so
  /// legacy rows do not accidentally enter the submit pipeline.
  int _submitRequestedFromRow(Map<String, Object?> row) {
    final Object? v = row['submit_requested'];
    if (v == null) {
      return 0;
    }
    if (v is int) {
      return v;
    }
    if (v is num) {
      return v.toInt();
    }
    return 0;
  }

  ReportOutboxEntry _fromRow(Map<String, Object?> row) {
    final String draftJson = row['draft_json']! as String;
    final ({ReportDraft draft, String title, String description}) parsed =
        ReportDraftJsonCodec.decode(draftJson);
    final String? mediaRaw = row['media_urls_json'] as String?;
    List<String>? mediaUrls;
    if (mediaRaw != null && mediaRaw.isNotEmpty) {
      final Object? m = jsonDecode(mediaRaw);
      if (m is List<dynamic>) {
        mediaUrls = m.whereType<String>().toList();
      }
    }
    return ReportOutboxEntry(
      id: row['id']! as String,
      idempotencyKey: row['idempotency_key']! as String,
      draft: parsed.draft,
      title: parsed.title,
      description: parsed.description,
      submitRequested: _submitRequestedFromRow(row) == 1,
      mediaUrls: mediaUrls,
      state: _stateFromDb(row['state']! as String),
      attemptCount: (row['attempt_count'] as int?) ?? 0,
      lastErrorCode: row['last_error_code'] as String?,
      lastErrorMessage: row['last_error_message'] as String?,
      cooldownUntilMs: row['cooldown_until_ms'] as int?,
      reportId: row['report_id'] as String?,
      createdAtMs: row['created_at_ms']! as int,
      updatedAtMs: row['updated_at_ms']! as int,
      currentStageName: row['current_stage'] as String?,
      attemptedStageNames: _attemptedStagesFromDb(
        row['attempted_stages_json'] as String?,
      ),
      lastPersistedAtMs: row['last_persisted_at_ms'] as int?,
    );
  }

  List<String> _attemptedStagesFromDb(String? raw) {
    if (raw == null || raw.isEmpty) {
      return const <String>[];
    }
    try {
      final Object? d = jsonDecode(raw);
      if (d is List<dynamic>) {
        return d.whereType<String>().toList();
      }
    } catch (_) {}
    return const <String>[];
  }

  Map<String, Object?> _toRow(ReportOutboxEntry e) {
    final String draftJson = jsonEncode(
      ReportDraftJsonCodec.encode(
        draft: e.draft,
        title: e.title,
        description: e.description,
      ),
    );
    return <String, Object?>{
      'id': e.id,
      'idempotency_key': e.idempotencyKey,
      'draft_json': draftJson,
      'state': _stateToDb(e.state),
      'submit_requested': e.submitRequested ? 1 : 0,
      'media_urls_json':
          e.mediaUrls == null || e.mediaUrls!.isEmpty
          ? null
          : jsonEncode(e.mediaUrls),
      'attempt_count': e.attemptCount,
      'last_error_code': e.lastErrorCode,
      'last_error_message': e.lastErrorMessage,
      'cooldown_until_ms': e.cooldownUntilMs,
      'report_id': e.reportId,
      'created_at_ms': e.createdAtMs,
      'updated_at_ms': e.updatedAtMs,
      'current_stage': e.currentStageName,
      'attempted_stages_json': e.attemptedStageNames.isEmpty
          ? null
          : jsonEncode(e.attemptedStageNames),
      'last_persisted_at_ms': e.lastPersistedAtMs,
    };
  }

  @override
  Future<void> insert(ReportOutboxEntry entry) async {
    await _dao.insertRow(_toRow(entry));
  }

  @override
  Future<void> update(ReportOutboxEntry entry) async {
    await _dao.updateRow(_toRow(entry), entry.id);
  }

  @override
  Future<ReportOutboxEntry?> getById(String id) async {
    final List<Map<String, Object?>> rows = await _dao.queryById(id);
    if (rows.isEmpty) {
      return null;
    }
    return _fromRow(rows.first);
  }

  @override
  Future<ReportOutboxEntry?> getNextProcessable() async {
    final int now = DateTime.now().millisecondsSinceEpoch;
    final List<Map<String, Object?>> rows = await _dao.rawQueryNextProcessable(
      now,
    );
    if (rows.isEmpty) {
      return null;
    }
    return _fromRow(rows.first);
  }

  @override
  Future<ReportOutboxEntry?> getWizardDraftEntry() async {
    return getById(kReportWizardDraftRowId);
  }

  @override
  Future<int> countSubmitPipeline() => _dao.rawCountSubmitPipeline();

  @override
  Future<int> countAllRows() => _dao.rawCountAllRows();

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
    final int persistedAt = lastPersistedAtMs ?? now;
    await _dao.runTransaction((Transaction txn) async {
      final List<Map<String, Object?>> existingRows = await _dao.queryByIdTxn(
        txn,
        kReportWizardDraftRowId,
      );
      final ReportOutboxEntry? existing = existingRows.isEmpty
          ? null
          : _fromRow(existingRows.first);
      if (existing == null) {
        final ReportOutboxEntry entry = ReportOutboxEntry(
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
          lastPersistedAtMs: persistedAt,
        );
        await txn.insert(
          ReportOutboxDatabase.tableOutbox,
          _toRow(entry),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
        return;
      }
      await txn.update(
        ReportOutboxDatabase.tableOutbox,
        _toRow(
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
            attemptedStageNames:
                attemptedStageNames ?? existing.attemptedStageNames,
            lastPersistedAtMs: persistedAt,
          ),
        ),
        where: 'id = ?',
        whereArgs: <Object>[kReportWizardDraftRowId],
      );
    });
  }

  @override
  Future<void> delete(String id) async {
    await _dao.deleteWhereId(id);
  }
}
