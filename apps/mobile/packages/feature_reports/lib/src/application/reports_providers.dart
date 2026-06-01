import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:feature_reports/src/application/report_wizard_submit_port.dart';
import 'package:feature_reports/src/application/reports_list_session.dart';
import 'package:feature_reports/src/data/outbox/report_draft_photo_store.dart';
import 'package:feature_reports/src/data/outbox/report_draft_repository.dart';
import 'package:feature_reports/src/data/outbox/report_outbox_coordinator.dart';
import 'package:feature_reports/src/data/outbox/report_outbox_repository.dart';
import 'package:feature_reports/src/data/reports_realtime/reports_realtime_service.dart';
import 'package:feature_reports/src/domain/repositories/reports_api_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:chisto_infrastructure/core/providers/refresh_signals_providers.dart'
    show profileRefreshTickProvider;

final reportsApiRepositoryProvider = Provider<ReportsApiRepository>((Ref ref) {
  return ref.watch(appBootstrapProvider).reportsApiRepository;
});

final reportOutboxRepositoryProvider = Provider<ReportOutboxRepository>((
  Ref ref,
) {
  return ref.watch(appBootstrapProvider).reportOutboxRepository;
});

final reportDraftRepositoryProvider = Provider<ReportDraftRepository>((
  Ref ref,
) {
  return ref.watch(appBootstrapProvider).reportDraftRepository;
});

final reportDraftPhotoStoreProvider = Provider<ReportDraftPhotoStore>((
  Ref ref,
) {
  return ref.watch(appBootstrapProvider).reportDraftPhotoStore;
});

final reportOutboxCoordinatorProvider = Provider<ReportOutboxCoordinator>((
  Ref ref,
) {
  return ref.watch(appBootstrapProvider).reportOutboxCoordinator;
});

final reportWizardSubmitPortProvider = Provider<ReportWizardSubmitPort>((
  Ref ref,
) {
  return ref.watch(appBootstrapProvider).reportWizardSubmitPort;
});

final reportsRealtimeServiceProvider = Provider<ReportsRealtimeService>((
  Ref ref,
) {
  return ref.watch(appBootstrapProvider).reportsRealtimeService;
});

final reportsListSessionProvider = Provider<ReportsListSession>((Ref ref) {
  return ref.watch(appBootstrapProvider).reportsListSession;
});
