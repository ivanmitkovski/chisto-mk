import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/network/api_client.dart';
import 'package:feature_events/src/data/organizer_quiz_payload.dart';
import 'package:feature_events/src/domain/models/organizer_certification_submit_result.dart';
import 'package:feature_events/src/domain/models/organizer_quiz_payload.dart';
import 'package:feature_events/src/domain/repositories/organizer_certification_repository.dart';

class ApiOrganizerCertificationRepository
    implements OrganizerCertificationRepositoryPort {
  ApiOrganizerCertificationRepository({required ApiClient client})
    : _client = client;

  final ApiClient _client;

  @override
  Future<OrganizerQuizPayload> fetchQuiz() async {
    final ApiResponse response = await _client.get(
      '/auth/me/organizer-certification/quiz',
    );
    final OrganizerQuizPayload? payload = parseOrganizerQuizPayload(
      response.json,
      rawBody: response.body,
    );
    if (payload == null) {
      throw AppError.server(message: 'Invalid organizer quiz response');
    }
    return payload;
  }

  @override
  Future<OrganizerCertificationSubmitResult> submitCertification({
    required String quizSession,
    required List<Map<String, String>> answers,
  }) async {
    final ApiResponse response = await _client.post(
      '/auth/me/organizer-certification',
      body: <String, dynamic>{'quizSession': quizSession, 'answers': answers},
    );
    final Map<String, dynamic>? json = response.json;
    if (json == null) {
      throw AppError.server(
        message: 'Invalid organizer certification response',
      );
    }
    final String? certifiedAtRaw = json['organizerCertifiedAt'] as String?;
    return OrganizerCertificationSubmitResult(
      passed: json['passed'] as bool? ?? false,
      alreadyCertified: json['alreadyCertified'] as bool? ?? false,
      correctCount: (json['correctCount'] as num?)?.toInt() ?? 0,
      totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
      pointsAwarded: (json['pointsAwarded'] as num?)?.toInt() ?? 0,
      organizerCertifiedAt: certifiedAtRaw == null
          ? null
          : DateTime.tryParse(certifiedAtRaw),
    );
  }
}
