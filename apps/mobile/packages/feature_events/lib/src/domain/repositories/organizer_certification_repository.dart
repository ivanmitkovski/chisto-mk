import 'package:feature_events/src/domain/models/organizer_certification_submit_result.dart';
import 'package:feature_events/src/domain/models/organizer_quiz_payload.dart';

/// Organizer certification quiz and submission APIs.
abstract class OrganizerCertificationRepositoryPort {
  Future<OrganizerQuizPayload> fetchQuiz();

  Future<OrganizerCertificationSubmitResult> submitCertification({
    required String quizSession,
    required List<Map<String, String>> answers,
  });
}
