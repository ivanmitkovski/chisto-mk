import 'package:chisto_infrastructure/core/config/app_config.dart';
import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/network/api_client.dart';
import 'package:chisto_infrastructure/core/network/request_cancellation.dart';
import 'package:feature_events/src/data/api_organizer_certification_repository.dart';
import 'package:feature_events/src/domain/models/organizer_certification_submit_result.dart';
import 'package:feature_events/src/domain/models/organizer_quiz_payload.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient()
    : super(
        config: AppConfig.dev,
        accessToken: () => null,
        onUnauthorized: (_) {},
      );

  int getCalls = 0;
  int postCalls = 0;
  Object? lastPostBody;
  final Map<String, ApiResponse> _getResponses = <String, ApiResponse>{};
  final Map<String, ApiResponse> _postResponses = <String, ApiResponse>{};

  void stubGet(String path, Map<String, dynamic> json) {
    _getResponses[path] = ApiResponse(statusCode: 200, json: json);
  }

  void stubPost(String path, ApiResponse response) {
    _postResponses[path] = response;
  }

  @override
  Future<ApiResponse> get(
    String path, {
    RequestCancellationToken? cancellation,
    Map<String, String>? headers,
  }) async {
    getCalls += 1;
    final ApiResponse? response = _getResponses[path];
    if (response == null) {
      throw const AppError(code: 'NOT_FOUND', message: 'missing stub');
    }
    return response;
  }

  @override
  Future<ApiResponse> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
    RequestCancellationToken? cancellation,
  }) async {
    postCalls += 1;
    lastPostBody = body;
    final ApiResponse? response = _postResponses[path];
    if (response == null) {
      throw const AppError(code: 'NOT_FOUND', message: 'missing stub');
    }
    return response;
  }
}

Map<String, dynamic> _quizJson() {
  return <String, dynamic>{
    'quizSession': 'jwt-here',
    'questions': <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'q1',
        'text': 'Safety first?',
        'options': <Map<String, dynamic>>[
          <String, dynamic>{'id': 'a', 'text': 'Yes'},
        ],
      },
    ],
  };
}

void main() {
  test('fetchQuiz GETs quiz endpoint and parses payload', () async {
    final _FakeApiClient client = _FakeApiClient();
    client.stubGet('/auth/me/organizer-certification/quiz', _quizJson());
    final ApiOrganizerCertificationRepository repo =
        ApiOrganizerCertificationRepository(client: client);

    final OrganizerQuizPayload payload = await repo.fetchQuiz();

    expect(client.getCalls, 1);
    expect(payload.session, 'jwt-here');
    expect(payload.rawQuestions, hasLength(1));
  });

  test('fetchQuiz throws when quiz payload is invalid', () async {
    final _FakeApiClient client = _FakeApiClient();
    client.stubGet('/auth/me/organizer-certification/quiz', <String, dynamic>{
      'quizSession': 'jwt-here',
      'questions': <dynamic>[],
    });
    final ApiOrganizerCertificationRepository repo =
        ApiOrganizerCertificationRepository(client: client);

    await expectLater(
      repo.fetchQuiz(),
      throwsA(
        predicate<AppError>(
          (AppError e) => e.message.contains('Invalid organizer quiz response'),
        ),
      ),
    );
  });

  test('submitCertification POSTs body and parses result', () async {
    final _FakeApiClient client = _FakeApiClient();
    client.stubPost(
      '/auth/me/organizer-certification',
      ApiResponse(
        statusCode: 200,
        json: <String, dynamic>{
          'passed': true,
          'alreadyCertified': false,
          'correctCount': 4,
          'totalQuestions': 5,
          'pointsAwarded': 25,
          'organizerCertifiedAt': '2026-05-01T08:00:00.000Z',
        },
      ),
    );
    final ApiOrganizerCertificationRepository repo =
        ApiOrganizerCertificationRepository(client: client);

    final OrganizerCertificationSubmitResult result = await repo
        .submitCertification(
          quizSession: 'session-1',
          answers: <Map<String, String>>[
            <String, String>{'questionId': 'q1', 'optionId': 'a'},
          ],
        );

    expect(client.postCalls, 1);
    expect(client.lastPostBody, <String, dynamic>{
      'quizSession': 'session-1',
      'answers': <Map<String, String>>[
        <String, String>{'questionId': 'q1', 'optionId': 'a'},
      ],
    });
    expect(result.passed, isTrue);
    expect(result.alreadyCertified, isFalse);
    expect(result.correctCount, 4);
    expect(result.totalQuestions, 5);
    expect(result.pointsAwarded, 25);
    expect(
      result.organizerCertifiedAt,
      DateTime.parse('2026-05-01T08:00:00.000Z'),
    );
  });

  test('submitCertification throws when response json is null', () async {
    final _FakeApiClient client = _FakeApiClient();
    client.stubPost(
      '/auth/me/organizer-certification',
      const ApiResponse(statusCode: 200),
    );
    final ApiOrganizerCertificationRepository repo =
        ApiOrganizerCertificationRepository(client: client);

    await expectLater(
      repo.submitCertification(
        quizSession: 'session-1',
        answers: const <Map<String, String>>[],
      ),
      throwsA(
        predicate<AppError>(
          (AppError e) =>
              e.message.contains('Invalid organizer certification response'),
        ),
      ),
    );
  });
}
