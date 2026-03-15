import 'package:flutter/foundation.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_draft.dart';

abstract class ReportsRepository implements Listenable {
  List<ReportDraft> get drafts;
  bool get isReady;
  Future<void> get ready;

  void saveDraft(ReportDraft draft);
  void deleteDraft(String id);
  ReportDraft? findById(String id);
  Future<void> submitDraft(String id);
}
