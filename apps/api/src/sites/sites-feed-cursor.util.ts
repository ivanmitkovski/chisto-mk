import type { Prisma } from '../prisma-client';

export function encodeRankedFeedCursor(rankingScore: number, id: string): string {
  return `r|${rankingScore.toFixed(8)}|${id}`;
}

export function encodeHybridFeedCursor(
  rankingScore: number,
  id: string,
  createdAt: Date,
): string {
  return `h|${rankingScore.toFixed(8)}|${id}|${createdAt.getTime()}`;
}

export function decodeFeedCursor(
  cursor: string | undefined,
  hybridRanked: boolean,
): { dbClause: Prisma.SiteWhereInput | null; hybrid?: { score: number; id: string } } | null {
  if (!cursor) return null;
  const [kind, first, second] = cursor.split('|');
  if (kind === 'r') {
    const score = Number(first);
    const id = second;
    if (!Number.isFinite(score) || !id) return { dbClause: null };
    return { dbClause: null, hybrid: { score, id } };
  }
  if (kind === 'h') {
    const score = Number(first);
    const id = second;
    if (!hybridRanked || !Number.isFinite(score) || !id) return { dbClause: null };
    return { dbClause: null, hybrid: { score, id } };
  }
  const timestampRaw = kind === 'c' ? first : kind;
  const id = kind === 'c' ? second : first;
  const timestamp = Number(timestampRaw);
  if (!Number.isFinite(timestamp) || !id) return { dbClause: null };
  const createdAt = new Date(timestamp);
  if (Number.isNaN(createdAt.getTime())) return { dbClause: null };
  return {
    dbClause: {
      OR: [
        { createdAt: { lt: createdAt } },
        {
          AND: [{ createdAt }, { id: { lt: id } }],
        },
      ],
    },
  };
}

export function isAfterRankedCursor(
  row: { rankingScore: number; id: string },
  cursor: { score: number; id: string },
): boolean {
  if (row.rankingScore < cursor.score) return true;
  if (row.rankingScore > cursor.score) return false;
  return row.id.localeCompare(cursor.id) < 0;
}
