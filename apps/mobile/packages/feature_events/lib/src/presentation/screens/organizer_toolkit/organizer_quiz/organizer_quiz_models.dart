part of 'package:feature_events/src/presentation/screens/organizer_toolkit/organizer_quiz_screen.dart';

class _QuizOption {
  const _QuizOption({required this.id, required this.text});
  final String id;
  final String text;
}

class _QuizQuestion {
  const _QuizQuestion({
    required this.id,
    required this.text,
    required this.options,
  });
  final String id;
  final String text;
  final List<_QuizOption> options;
}

class _QuizResult {
  const _QuizResult({
    required this.passed,
    required this.correctCount,
    required this.totalQuestions,
    required this.pointsAwarded,
  });
  final bool passed;
  final int correctCount;
  final int totalQuestions;
  final int pointsAwarded;
}
