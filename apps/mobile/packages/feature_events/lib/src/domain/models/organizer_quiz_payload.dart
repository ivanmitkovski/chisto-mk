/// Parsed `GET /auth/me/organizer-certification/quiz` payload.
class OrganizerQuizPayload {
  const OrganizerQuizPayload({
    required this.session,
    required this.rawQuestions,
  });

  final String session;
  final List<dynamic> rawQuestions;
}
