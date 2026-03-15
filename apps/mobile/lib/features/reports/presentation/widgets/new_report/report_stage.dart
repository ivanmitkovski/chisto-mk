enum ReportStage {
  evidence(
    'Evidence',
    'Report a pollution site',
    'Start with a clear photo of the site.',
    'Evidence',
    'Next',
    'Start with one clear overview photo.',
    'Required: 1+ photo',
    'Best with 1-2 strong shots',
  ),
  details(
    'Details',
    'Describe the issue',
    'Choose the closest category and add short context if needed.',
    'Details',
    'Next',
    'Keep the description brief and factual.',
    'Required: category',
    'Optional: short note',
  ),
  location(
    'Location',
    'Confirm the location',
    'Place the pin on the exact site.',
    'Location',
    'Next',
    'Confirm the pin on the exact spot.',
    'Required: confirm pin',
    'Inside Macedonia',
  ),
  review(
    'Review',
    'Final review',
    'Check the essentials, then submit.',
    'Review',
    'Submit report',
    'Give everything one last look, then submit.',
    'Final check',
    null,
  );

  const ReportStage(
    this.eyebrow,
    this.title,
    this.subtitle,
    this.shortLabel,
    this.primaryActionLabel,
    this.footerHint,
    this.primaryRequirementLabel,
    this.secondaryRequirementLabel,
  );

  final String eyebrow;
  final String title;
  final String subtitle;
  final String shortLabel;
  final String primaryActionLabel;
  final String footerHint;
  final String primaryRequirementLabel;
  final String? secondaryRequirementLabel;
}
