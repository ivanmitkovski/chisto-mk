/// <reference types="jest" />

import { BadRequestException, ForbiddenException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { OrganizerCertificationService } from '../../src/auth/organizer-certification.service';
import {
  ORGANIZER_QUIZ_DRAW_SIZE,
  getOrganizerQuizQuestionById,
} from '../../src/auth/organizer-quiz-bank';

describe('OrganizerCertificationService', () => {
  const jwtSecret = 'organizer-cert-test-secret';
  let jwtService: JwtService;
  let prisma: {
    user: { findUnique: jest.Mock; update: jest.Mock };
    $transaction: jest.Mock;
  };
  let ecoEventPoints: { creditIfNew: jest.Mock };
  let service: OrganizerCertificationService;

  beforeEach(() => {
    jwtService = new JwtService({ secret: jwtSecret });
    prisma = {
      user: {
        findUnique: jest.fn(),
        update: jest.fn(),
      },
      $transaction: jest.fn(async (fn: (tx: typeof prisma) => Promise<unknown>) => fn(prisma)),
    };
    ecoEventPoints = {
      creditIfNew: jest.fn().mockResolvedValue(5),
    };
    service = new OrganizerCertificationService(
      prisma as never,
      ecoEventPoints as never,
      jwtService,
    );
    prisma.user.findUnique.mockResolvedValue({ organizerCertifiedAt: null });
  });

  describe('getQuiz', () => {
    it('returns quizSession and exactly ORGANIZER_QUIZ_DRAW_SIZE questions', async () => {
      const out = await service.getQuiz('user-1', 'en');
      expect(out.quizSession).toBeTruthy();
      expect(out.questions).toHaveLength(ORGANIZER_QUIZ_DRAW_SIZE);
      const payload = jwtService.verify<{ typ: string; sub: string; qids: string[] }>(out.quizSession);
      expect(payload.typ).toBe('organizer_quiz');
      expect(payload.sub).toBe('user-1');
      expect(payload.qids).toHaveLength(ORGANIZER_QUIZ_DRAW_SIZE);
      expect(new Set(payload.qids).size).toBe(ORGANIZER_QUIZ_DRAW_SIZE);
      const ids = new Set(out.questions.map((q) => q.id));
      expect(ids.size).toBe(ORGANIZER_QUIZ_DRAW_SIZE);
      expect(out.questions.map((q) => q.id)).toEqual(payload.qids);
    });

    it('throws when user is already certified', async () => {
      prisma.user.findUnique.mockResolvedValueOnce({
        organizerCertifiedAt: new Date('2026-02-01T00:00:00.000Z'),
      });
      await expect(service.getQuiz('user-1', 'en')).rejects.toThrow(ForbiddenException);
    });
  });

  describe('submit', () => {
    it('returns alreadyCertified without writing when user is certified', async () => {
      prisma.user.findUnique.mockResolvedValue({
        organizerCertifiedAt: new Date('2026-01-01T00:00:00.000Z'),
      });
      const out = await service.submit('user-1', {
        quizSession: 'irrelevant',
        answers: [],
      });
      expect(out.alreadyCertified).toBe(true);
      expect(out.passed).toBe(true);
      expect(prisma.$transaction).not.toHaveBeenCalled();
    });

    it('rejects expired quiz session', async () => {
      const expired = jwtService.sign(
        { typ: 'organizer_quiz', sub: 'user-1', qids: ['q1_safety', 'q2_moderation', 'q3_checkin', 'q4_weather', 'q5_waste'] },
        { expiresIn: -60 },
      );
      await expect(
        service.submit('user-1', {
          quizSession: expired,
          answers: [],
        }),
      ).rejects.toThrow(BadRequestException);
    });

    it('rejects quiz session for another user', async () => {
      const { quizSession } = await service.getQuiz('other-user', 'en');
      const payload = jwtService.verify<{ qids: string[] }>(quizSession);
      const answers = payload.qids.map((qid) => {
        const q = getOrganizerQuizQuestionById(qid)!;
        return { questionId: qid, selectedOptionId: q.correctOptionId };
      });
      await expect(service.submit('user-1', { quizSession, answers })).rejects.toThrow(BadRequestException);
    });

    it('fails when one answer is wrong', async () => {
      const { quizSession, questions } = await service.getQuiz('user-1', 'en');
      const answers = buildCorrectAnswersFromSession(quizSession, jwtService, 'user-1');
      const first = getOrganizerQuizQuestionById(questions[0]!.id)!;
      const wrongOpt = first.options.find((o) => o.id !== first.correctOptionId)!.id;
      answers[0] = { questionId: first.id, selectedOptionId: wrongOpt };
      const out = await service.submit('user-1', { quizSession, answers });
      expect(out.passed).toBe(false);
      expect(out.correctCount).toBeLessThan(ORGANIZER_QUIZ_DRAW_SIZE);
      expect(prisma.$transaction).not.toHaveBeenCalled();
    });

    it('passes and persists certification when all answers correct', async () => {
      const { quizSession, questions } = await service.getQuiz('user-1', 'en');
      const answers = buildCorrectAnswersFromQuestions(questions);
      const out = await service.submit('user-1', { quizSession, answers });
      expect(out.passed).toBe(true);
      expect(out.alreadyCertified).toBe(false);
      expect(out.organizerCertifiedAt).toBeTruthy();
      expect(prisma.$transaction).toHaveBeenCalled();
      expect(ecoEventPoints.creditIfNew).toHaveBeenCalled();
    });
  });
});

function buildCorrectAnswersFromSession(
  quizSession: string,
  jwt: JwtService,
  expectedSub: string,
): { questionId: string; selectedOptionId: string }[] {
  const payload = jwt.verify<{ sub: string; qids: string[] }>(quizSession);
  expect(payload.sub).toBe(expectedSub);
  return payload.qids.map((qid) => {
    const q = getOrganizerQuizQuestionById(qid);
    if (!q) {
      throw new Error(`missing ${qid}`);
    }
    return { questionId: qid, selectedOptionId: q.correctOptionId };
  });
}

function buildCorrectAnswersFromQuestions(
  questions: Array<{ id: string; options: Array<{ id: string }> }>,
): { questionId: string; selectedOptionId: string }[] {
  return questions.map((qu) => {
    const full = getOrganizerQuizQuestionById(qu.id);
    if (!full) {
      throw new Error(`missing ${qu.id}`);
    }
    return { questionId: qu.id, selectedOptionId: full.correctOptionId };
  });
}
