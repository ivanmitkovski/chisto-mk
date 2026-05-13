import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  InternalServerErrorException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { JsonWebTokenError, TokenExpiredError } from 'jsonwebtoken';
import { PrismaService } from '../prisma/prisma.service';
import { EcoEventPointsService } from '../gamification/eco-event-points.service';
import {
  POINTS_ORGANIZER_CERTIFIED,
  REASON_ORGANIZER_CERTIFIED,
} from '../gamification/gamification.constants';
import {
  ORGANIZER_QUIZ_DRAW_SIZE,
  ORGANIZER_QUIZ_JWT_TYP,
  ORGANIZER_QUIZ_SESSION_TTL_SEC,
  buildShuffledQuizForQuestionIds,
  getOrganizerQuizQuestionById,
  pickRandomQuestionIds,
  resolveQuizLocale,
  scoreOrganizerQuizAnswers,
  type OrganizerQuizAnswer,
} from './organizer-quiz-bank';
import type { SubmitOrganizerCertificationDto } from './dto/submit-organizer-certification.dto';

type OrganizerQuizJwtPayload = {
  typ: string;
  sub: string;
  qids: string[];
};

@Injectable()
export class OrganizerCertificationService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly ecoEventPoints: EcoEventPointsService,
    private readonly jwtService: JwtService,
  ) {}

  async getQuiz(userId: string, acceptLanguage: string): Promise<{
    quizSession: string;
    questions: ReturnType<typeof buildShuffledQuizForQuestionIds>;
  }> {
    const existing = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { organizerCertifiedAt: true },
    });
    if (existing?.organizerCertifiedAt != null) {
      throw new ForbiddenException({
        code: 'ORGANIZER_CERTIFICATION_ALREADY_CERTIFIED',
        message: 'Organizer certification was already completed.',
      });
    }

    const lang = resolveQuizLocale(acceptLanguage);
    let qids: string[];
    let questions: ReturnType<typeof buildShuffledQuizForQuestionIds>;
    try {
      qids = pickRandomQuestionIds(ORGANIZER_QUIZ_DRAW_SIZE);
      questions = buildShuffledQuizForQuestionIds(qids, lang);
    } catch (err) {
      throw new InternalServerErrorException({
        code: 'ORGANIZER_QUIZ_BANK_INVARIANT',
        message: err instanceof Error ? err.message : 'Organizer quiz generation failed',
      });
    }
    const quizSession = this.jwtService.sign(
      { typ: ORGANIZER_QUIZ_JWT_TYP, sub: userId, qids },
      { expiresIn: ORGANIZER_QUIZ_SESSION_TTL_SEC },
    );
    return { quizSession, questions };
  }

  async submit(
    userId: string,
    dto: SubmitOrganizerCertificationDto,
  ): Promise<{
    passed: boolean;
    correctCount: number;
    totalQuestions: number;
    alreadyCertified: boolean;
    pointsAwarded: number;
    organizerCertifiedAt: string | null;
  }> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { organizerCertifiedAt: true },
    });

    if (user?.organizerCertifiedAt != null) {
      return {
        passed: true,
        correctCount: ORGANIZER_QUIZ_DRAW_SIZE,
        totalQuestions: ORGANIZER_QUIZ_DRAW_SIZE,
        alreadyCertified: true,
        pointsAwarded: 0,
        organizerCertifiedAt: user.organizerCertifiedAt.toISOString(),
      };
    }

    const orderedQuestionIds = this.verifyQuizSessionOrThrow(userId, dto.quizSession);
    const answers = this.assertAnswersAlignSession(orderedQuestionIds, dto.answers);

    const { correctCount, totalQuestions, passed } = scoreOrganizerQuizAnswers(orderedQuestionIds, answers);

    if (!passed) {
      return {
        passed: false,
        correctCount,
        totalQuestions,
        alreadyCertified: false,
        pointsAwarded: 0,
        organizerCertifiedAt: null,
      };
    }

    const now = new Date();
    let pointsAwarded = 0;
    await this.prisma.$transaction(async (tx) => {
      await tx.user.update({
        where: { id: userId },
        data: { organizerCertifiedAt: now },
      });
      pointsAwarded = await this.ecoEventPoints.creditIfNew(tx, {
        userId,
        delta: POINTS_ORGANIZER_CERTIFIED,
        reasonCode: REASON_ORGANIZER_CERTIFIED,
        referenceType: 'User',
        referenceId: `organizer_cert:${userId}`,
      });
    });

    return {
      passed: true,
      correctCount,
      totalQuestions,
      alreadyCertified: false,
      pointsAwarded,
      organizerCertifiedAt: now.toISOString(),
    };
  }

  private verifyQuizSessionOrThrow(userId: string, token: string): string[] {
    let payload: OrganizerQuizJwtPayload;
    try {
      payload = this.jwtService.verify<OrganizerQuizJwtPayload>(token);
    } catch (err: unknown) {
      if (err instanceof TokenExpiredError) {
        throw new BadRequestException({
          code: 'ORGANIZER_QUIZ_SESSION_EXPIRED',
          message: 'Quiz session expired. Start again from the quiz screen.',
        });
      }
      if (err instanceof JsonWebTokenError) {
        throw new BadRequestException({
          code: 'ORGANIZER_QUIZ_SESSION_INVALID',
          message: 'Invalid quiz session.',
        });
      }
      throw new BadRequestException({
        code: 'ORGANIZER_QUIZ_SESSION_INVALID',
        message: 'Invalid quiz session.',
      });
    }

    if (
      payload.typ !== ORGANIZER_QUIZ_JWT_TYP ||
      typeof payload.sub !== 'string' ||
      payload.sub !== userId ||
      !Array.isArray(payload.qids) ||
      payload.qids.length !== ORGANIZER_QUIZ_DRAW_SIZE
    ) {
      throw new BadRequestException({
        code: 'ORGANIZER_QUIZ_SESSION_INVALID',
        message: 'Invalid quiz session.',
      });
    }

    const unique = new Set(payload.qids);
    if (unique.size !== ORGANIZER_QUIZ_DRAW_SIZE) {
      throw new BadRequestException({
        code: 'ORGANIZER_QUIZ_SESSION_INVALID',
        message: 'Invalid quiz session.',
      });
    }

    return payload.qids;
  }

  private assertAnswersAlignSession(
    orderedQuestionIds: string[],
    answers: SubmitOrganizerCertificationDto['answers'],
  ): OrganizerQuizAnswer[] {
    if (answers.length !== orderedQuestionIds.length) {
      throw new BadRequestException({
        code: 'ORGANIZER_QUIZ_ANSWERS_MISMATCH',
        message: 'Each quiz question must be answered exactly once.',
      });
    }
    const orderedSet = new Set(orderedQuestionIds);
    const mapped: OrganizerQuizAnswer[] = answers.map((a) => ({
      questionId: a.questionId,
      selectedOptionId: a.selectedOptionId,
    }));
    const byQ = new Map(mapped.map((a) => [a.questionId, a.selectedOptionId]));
    if (byQ.size !== mapped.length) {
      throw new BadRequestException({
        code: 'ORGANIZER_QUIZ_ANSWERS_MISMATCH',
        message: 'Duplicate answers for the same question.',
      });
    }
    for (const qid of orderedQuestionIds) {
      if (!byQ.has(qid)) {
        throw new BadRequestException({
          code: 'ORGANIZER_QUIZ_ANSWERS_MISMATCH',
          message: 'Missing answer for a quiz question.',
        });
      }
    }
    for (const k of byQ.keys()) {
      if (!orderedSet.has(k)) {
        throw new BadRequestException({
          code: 'ORGANIZER_QUIZ_ANSWERS_MISMATCH',
          message: 'Answers do not match this quiz session.',
        });
      }
    }
    for (const qid of orderedQuestionIds) {
      const q = getOrganizerQuizQuestionById(qid);
      if (!q) {
        throw new BadRequestException({
          code: 'ORGANIZER_QUIZ_SESSION_INVALID',
          message: 'Invalid quiz session.',
        });
      }
      const sel = byQ.get(qid)!;
      const optionIds = new Set(q.options.map((o) => o.id));
      if (!optionIds.has(sel)) {
        throw new BadRequestException({
          code: 'ORGANIZER_QUIZ_INVALID',
          message: 'Unknown answer option for this question.',
        });
      }
    }
    return mapped;
  }
}
