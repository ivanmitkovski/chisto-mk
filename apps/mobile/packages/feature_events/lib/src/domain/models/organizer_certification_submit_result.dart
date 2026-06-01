/// Outcome of `POST /auth/me/organizer-certification`.
class OrganizerCertificationSubmitResult {
  const OrganizerCertificationSubmitResult({
    required this.passed,
    required this.alreadyCertified,
    required this.correctCount,
    required this.totalQuestions,
    required this.pointsAwarded,
    this.organizerCertifiedAt,
  });

  final bool passed;
  final bool alreadyCertified;
  final int correctCount;
  final int totalQuestions;
  final int pointsAwarded;
  final DateTime? organizerCertifiedAt;
}
