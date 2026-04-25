import { BadRequestException, Injectable } from '@nestjs/common';
import { Prisma } from '../prisma-client';

import { GamificationService } from './gamification.service';
import { PrismaService } from '../prisma/prisma.service';

const DEFAULT_LIMIT = 30;
const MAX_LIMIT = 50;
const MAX_MILESTONE_SCAN = 2000;

export type PointHistoryMilestone = {
  reachedAt: string;
  level: number;
  levelTierKey: string;
  levelDisplayName: string;
};

export type PointHistoryItem = {
  id: string;
  createdAt: string;
  delta: number;
  reasonCode: string;
  referenceType: string | null;
  referenceId: string | null;
};

export function computeLevelMilestonesFromAscRows(
  rows: ReadonlyArray<{ readonly createdAt: Date; readonly delta: number }>,
  gamification: GamificationService,
  locale = 'en',
): PointHistoryMilestone[] {
  let xp = 0;
  let prevLevel = 1;
  const out: PointHistoryMilestone[] = [];
  for (const row of rows) {
    if (row.delta <= 0) {
      continue;
    }
    xp += row.delta;
    const prog = gamification.getLevelProgress(xp, locale);
    if (prog.level > prevLevel) {
      out.push({
        reachedAt: row.createdAt.toISOString(),
        level: prog.level,
        levelTierKey: prog.levelTierKey,
        levelDisplayName: prog.levelDisplayName,
      });
      prevLevel = prog.level;
    }
  }
  return out;
}

function encodeCursor(createdAt: Date, id: string): string {
  const payload = JSON.stringify({ c: createdAt.toISOString(), i: id });
  return Buffer.from(payload, 'utf8').toString('base64url');
}

function decodeCursor(cursor: string): { createdAt: Date; id: string } {
  let parsed: unknown;
  try {
    const raw = Buffer.from(cursor, 'base64url').toString('utf8');
    parsed = JSON.parse(raw) as unknown;
  } catch {
    throw new BadRequestException({
      code: 'INVALID_POINT_HISTORY_CURSOR',
      message: 'Invalid cursor',
    });
  }
  if (
    typeof parsed !== 'object' ||
    parsed === null ||
    !('c' in parsed) ||
    !('i' in parsed)
  ) {
    throw new BadRequestException({
      code: 'INVALID_POINT_HISTORY_CURSOR',
      message: 'Invalid cursor',
    });
  }
  const rec = parsed as { c: unknown; i: unknown };
  if (typeof rec.c !== 'string' || typeof rec.i !== 'string' || rec.i.length === 0) {
    throw new BadRequestException({
      code: 'INVALID_POINT_HISTORY_CURSOR',
      message: 'Invalid cursor',
    });
  }
  const createdAt = new Date(rec.c);
  if (Number.isNaN(createdAt.getTime())) {
    throw new BadRequestException({
      code: 'INVALID_POINT_HISTORY_CURSOR',
      message: 'Invalid cursor',
    });
  }
  return { createdAt, id: rec.i };
}

@Injectable()
export class PointHistoryService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly gamification: GamificationService,
  ) {}

  async listForUser(
    userId: string,
    query: { limit?: number; cursor?: string },
    locale = 'en',
  ): Promise<{
    data: PointHistoryItem[];
    meta: { milestones: PointHistoryMilestone[]; nextCursor: string | null };
  }> {
    const limit = Math.min(Math.max(query.limit ?? DEFAULT_LIMIT, 1), MAX_LIMIT);
    const hasCursor = query.cursor != null && query.cursor.trim() !== '';

    let cursorCreatedAt: Date | undefined;
    let cursorId: string | undefined;
    if (hasCursor) {
      const decoded = decodeCursor(query.cursor!.trim());
      cursorCreatedAt = decoded.createdAt;
      cursorId = decoded.id;
    }

    const where: Prisma.PointTransactionWhereInput = { userId };
    if (cursorCreatedAt != null && cursorId != null) {
      where.OR = [
        { createdAt: { lt: cursorCreatedAt } },
        { AND: [{ createdAt: cursorCreatedAt }, { id: { lt: cursorId } }] },
      ];
    }

    const rows = await this.prisma.pointTransaction.findMany({
      where,
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: limit + 1,
      select: {
        id: true,
        createdAt: true,
        delta: true,
        reasonCode: true,
        referenceType: true,
        referenceId: true,
      },
    });

    const hasMore = rows.length > limit;
    const page = hasMore ? rows.slice(0, limit) : rows;
    const last = page.length > 0 ? page[page.length - 1] : null;
    const nextCursor =
      hasMore && last != null ? encodeCursor(last.createdAt, last.id) : null;

    let milestones: PointHistoryMilestone[] = [];
    if (!hasCursor) {
      const ascRows = await this.prisma.pointTransaction.findMany({
        where: { userId },
        orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
        take: MAX_MILESTONE_SCAN,
        select: { createdAt: true, delta: true },
      });
      milestones = computeLevelMilestonesFromAscRows(ascRows, this.gamification, locale);
    }

    const data: PointHistoryItem[] = page.map((r) => ({
      id: r.id,
      createdAt: r.createdAt.toISOString(),
      delta: r.delta,
      reasonCode: r.reasonCode,
      referenceType: r.referenceType,
      referenceId: r.referenceId,
    }));

    return {
      data,
      meta: { milestones, nextCursor },
    };
  }
}
