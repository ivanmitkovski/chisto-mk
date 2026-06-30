/// Pop result for [AppRoutes.newReport] / [NewReportScreen] (GoRouter route).
sealed class NewReportWizardPopResult {
  const NewReportWizardPopResult();
}

/// User chose "View this report" on the success dialog.
final class NewReportWizardViewReport extends NewReportWizardPopResult {
  const NewReportWizardViewReport(this.reportId);

  final String reportId;
}

/// User chose "View all reports", close, or dismissed to the list.
final class NewReportWizardViewReports extends NewReportWizardPopResult {
  const NewReportWizardViewReports();
}

/// User chose "Report another" — wizard stays open with a fresh draft.
final class NewReportWizardReportAnother extends NewReportWizardPopResult {
  const NewReportWizardReportAnother();
}
