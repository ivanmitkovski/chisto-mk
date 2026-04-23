import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:chisto_mobile/features/events/data/organizer_quiz_payload.dart';

void main() {
  group('parseOrganizerQuizPayload', () {
    test('parses camelCase top-level payload', () {
      final OrganizerQuizApiPayload? out = parseOrganizerQuizPayload(
        <String, dynamic>{
          'quizSession': 'jwt-here',
          'questions': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'q1',
              'text': 'T?',
              'options': <Map<String, dynamic>>[
                <String, dynamic>{'id': 'a', 'text': 'A'},
              ],
            },
          ],
        },
      );

      expect(out, isNotNull);
      expect(out!.session, 'jwt-here');
      expect(out.rawQuestions, hasLength(1));
    });

    test('parses snake_case session key', () {
      final OrganizerQuizApiPayload? out = parseOrganizerQuizPayload(
        <String, dynamic>{
          'quiz_session': 'tok',
          'questions': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'q1',
              'text': 'T',
              'options': <Map<String, dynamic>>[
                <String, dynamic>{'id': 'a', 'text': 'A'},
              ],
            },
          ],
        },
      );

      expect(out?.session, 'tok');
      expect(out?.rawQuestions, hasLength(1));
    });

    test('unwraps data envelope', () {
      final OrganizerQuizApiPayload? out = parseOrganizerQuizPayload(
        <String, dynamic>{
          'data': <String, dynamic>{
            'quizSession': 's',
            'questions': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'q1',
                'text': 'T',
                'options': <Map<String, dynamic>>[
                  <String, dynamic>{'id': 'a', 'text': 'A'},
                ],
              },
            ],
          },
        },
      );

      expect(out?.session, 's');
      expect(out?.rawQuestions, hasLength(1));
    });

    test('falls back to rawBody when json is null', () {
      const String body =
          '{"quizSession":"x","questions":[{"id":"q1","text":"Hi","options":[{"id":"o1","text":"One"}]}]}';

      final OrganizerQuizApiPayload? out = parseOrganizerQuizPayload(
        null,
        rawBody: body,
      );

      expect(out?.session, 'x');
      expect(out?.rawQuestions, hasLength(1));
    });

    test('returns null when questions empty', () {
      expect(
        parseOrganizerQuizPayload(
          <String, dynamic>{'quizSession': 'x', 'questions': <dynamic>[]},
        ),
        isNull,
      );
    });
  });

  group('asJsonObject', () {
    test('coerces generic Map from jsonDecode', () {
      final Object? raw = jsonDecode('{"id":"q"}');
      final Map<String, dynamic>? m = asJsonObject(raw);
      expect(m, isNotNull);
      expect(m!['id'], 'q');
    });
  });
}
