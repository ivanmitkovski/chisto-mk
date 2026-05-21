import 'package:chisto_mobile/core/providers/reports_providers.dart';
import 'package:chisto_mobile/features/reports/presentation/controllers/new_report_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

final newReportControllerProvider = Provider.autoDispose
    .family<NewReportController, XFile?>((Ref ref, XFile? initialPhoto) {
  final NewReportController controller = NewReportController(
    initialPhoto: initialPhoto,
    draftRepository: ref.watch(reportDraftRepositoryProvider),
    reportsApiRepository: ref.watch(reportsApiRepositoryProvider),
    reportSubmitPort: ref.watch(reportWizardSubmitPortProvider),
  );
  ref.onDispose(controller.dispose);
  return controller;
});
