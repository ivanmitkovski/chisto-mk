import { ORGANIZER_QUIZ_QUESTIONS } from '../../src/auth/quiz/quiz-bank.loader';

describe('organizer quiz bank JSON loader', () => {
  it('loads 18 questions with stable ids', () => {
    expect(ORGANIZER_QUIZ_QUESTIONS).toHaveLength(18);
    const ids = ORGANIZER_QUIZ_QUESTIONS.map((q) => q.id);
    expect(ids).toContain('q1_safety');
    expect(ids).toContain('q18_moderators');
  });

  it('each question has en/mk/sq text and valid correctOptionId', () => {
    for (const q of ORGANIZER_QUIZ_QUESTIONS) {
      expect(q.text.en.length).toBeGreaterThan(0);
      expect(q.text.mk.length).toBeGreaterThan(0);
      expect(q.text.sq.length).toBeGreaterThan(0);
      const optionIds = q.options.map((o) => o.id);
      expect(optionIds).toContain(q.correctOptionId);
    }
  });
});
