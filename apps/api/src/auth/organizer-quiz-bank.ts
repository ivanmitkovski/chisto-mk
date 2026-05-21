/**
 * Server-owned organizer certification quiz bank.
 * GET returns a random subset with shuffled options + signed quizSession;
 * POST validates selectedOptionId against correctOptionId for the issued question set only.
 */

import { randomInt } from 'crypto';
import { ORGANIZER_QUIZ_QUESTIONS } from './quiz/quiz-bank.loader';
import type { OrganizerQuizQuestion } from './quiz/questions.types';

export type { OrganizerQuizTopic, OrganizerQuizQuestion } from './quiz/questions.types';

/** Number of questions issued per certification attempt. */
export const ORGANIZER_QUIZ_DRAW_SIZE = 5;

/** JWT lifetime for binding POST answers to GET draw (seconds). */
export const ORGANIZER_QUIZ_SESSION_TTL_SEC = 900;

export const ORGANIZER_QUIZ_JWT_TYP = 'organizer_quiz' as const;

export { ORGANIZER_QUIZ_QUESTIONS } from './quiz/quiz-bank.loader';

const QUESTION_BY_ID = new Map(ORGANIZER_QUIZ_QUESTIONS.map((q) => [q.id, q]));

export function resolveQuizLocale(acceptLanguage: string): 'en' | 'mk' | 'sq' {
  const lang = acceptLanguage.slice(0, 2).toLowerCase();
  return lang === 'mk' || lang === 'sq' ? lang : 'en';
}

export function getOrganizerQuizQuestionById(id: string): OrganizerQuizQuestion | undefined {
  return QUESTION_BY_ID.get(id);
}

function shuffleCopy<T>(items: T[]): T[] {
  const out = [...items];
  for (let i = out.length - 1; i > 0; i--) {
    const j = randomInt(i + 1);
    const tmp = out[i]!;
    out[i] = out[j]!;
    out[j] = tmp;
  }
  return out;
}

/**
 * Cryptographically secure random subset of distinct question ids.
 */
export function pickRandomQuestionIds(count: number): string[] {
  const all = ORGANIZER_QUIZ_QUESTIONS.map((q) => q.id);
  if (count > all.length) {
    throw new Error(`ORGANIZER_QUIZ_DRAW_SIZE (${count}) exceeds bank size (${all.length})`);
  }
  const pool = shuffleCopy(all);
  return pool.slice(0, count);
}

export type LocalizedQuizOption = { id: string; text: string };

export type LocalizedQuizQuestion = {
  id: string;
  text: string;
  options: LocalizedQuizOption[];
};

export function localizeQuestion(q: OrganizerQuizQuestion, lang: 'en' | 'mk' | 'sq'): LocalizedQuizQuestion {
  const text = q.text[lang] ?? q.text.en;
  const options = q.options.map((o) => ({
    id: o.id,
    text: o.text[lang] ?? o.text.en,
  }));
  return { id: q.id, text, options: shuffleCopy(options) };
}

export function buildShuffledQuizForQuestionIds(
  questionIds: string[],
  lang: 'en' | 'mk' | 'sq',
): LocalizedQuizQuestion[] {
  const out: LocalizedQuizQuestion[] = [];
  for (const id of questionIds) {
    const q = QUESTION_BY_ID.get(id);
    if (!q) {
      throw new Error(`Unknown organizer quiz question id: ${id}`);
    }
    out.push(localizeQuestion(q, lang));
  }
  return out;
}

export type OrganizerQuizAnswer = { questionId: string; selectedOptionId: string };

/**
 * Score answers against the bank for the exact ordered question set from the quiz session.
 */
export function scoreOrganizerQuizAnswers(
  orderedQuestionIds: string[],
  answers: OrganizerQuizAnswer[],
): { correctCount: number; totalQuestions: number; passed: boolean } {
  const totalQuestions = orderedQuestionIds.length;
  const expected = new Set(orderedQuestionIds);
  const byQ = new Map(answers.map((a) => [a.questionId, a.selectedOptionId]));

  if (byQ.size !== answers.length || byQ.size !== totalQuestions) {
    return { correctCount: 0, totalQuestions, passed: false };
  }
  for (const k of byQ.keys()) {
    if (!expected.has(k)) {
      return { correctCount: 0, totalQuestions, passed: false };
    }
  }

  let correctCount = 0;
  for (const qid of orderedQuestionIds) {
    const q = QUESTION_BY_ID.get(qid);
    if (!q) {
      return { correctCount: 0, totalQuestions, passed: false };
    }
    const selected = byQ.get(qid);
    if (selected == null) {
      return { correctCount: 0, totalQuestions, passed: false };
    }
    const optionIds = new Set(q.options.map((o) => o.id));
    if (!optionIds.has(selected)) {
      return { correctCount: 0, totalQuestions, passed: false };
    }
    if (selected === q.correctOptionId) {
      correctCount += 1;
    }
  }

  const passed = correctCount === totalQuestions;
  return { correctCount, totalQuestions, passed };
}
