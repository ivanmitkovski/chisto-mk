export 'package:chisto_mobile/core/providers/refresh_signals_providers.dart'
    show profileRefreshTickProvider;

import 'package:chisto_mobile/core/bootstrap/app_bootstrap.dart';
import 'package:chisto_mobile/features/reports/application/report_wizard_submit_port.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_draft_photo_store.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_draft_repository.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_coordinator.dart';
import 'package:chisto_mobile/features/reports/data/outbox/report_outbox_repository.dart';
import 'package:chisto_mobile/features/reports/data/reports_realtime/reports_realtime_service.dart';
import 'package:chisto_mobile/features/reports/domain/repositories/reports_api_repository.dart';
import 'package:chisto_mobile/features/reports/presentation/controllers/reports_list_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final reportsApiRepositoryProvider = Provider<ReportsApiRepository>((Ref ref) {
  return AppBootstrap.instance.reportsApiRepository;
});

final reportOutboxRepositoryProvider = Provider<ReportOutboxRepository>((Ref ref) {
  return AppBootstrap.instance.reportOutboxRepository;
});

final reportDraftRepositoryProvider = Provider<ReportDraftRepository>((Ref ref) {
  return AppBootstrap.instance.reportDraftRepository;
});

final reportDraftPhotoStoreProvider = Provider<ReportDraftPhotoStore>((Ref ref) {
  return AppBootstrap.instance.reportDraftPhotoStore;
});

final reportOutboxCoordinatorProvider = Provider<ReportOutboxCoordinator>((Ref ref) {
  return AppBootstrap.instance.reportOutboxCoordinator;
});

final reportWizardSubmitPortProvider = Provider<ReportWizardSubmitPort>((Ref ref) {
  return AppBootstrap.instance.reportWizardSubmitPort;
});

final reportsRealtimeServiceProvider = Provider<ReportsRealtimeService>((Ref ref) {
  return AppBootstrap.instance.reportsRealtimeService;
});

final reportsListSessionProvider = Provider<ReportsListSession>((Ref ref) {
  return AppBootstrap.instance.reportsListSession;
});
