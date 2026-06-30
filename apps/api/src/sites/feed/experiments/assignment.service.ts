import { Injectable } from '@nestjs/common';
import { createHash } from 'crypto';
import { PrismaService } from '../../../prisma/prisma.service';
import type { FeedVariant } from '../feed-v2.types';

@Injectable()
export class AssignmentService {
  constructor(private readonly prisma: PrismaService) {}

  async assign(userId: string): Promise<FeedVariant> {
    const key = 'feed_v2_ranking';
    const rows = await this.prisma.$queryRaw<Array<{ variant: string }>>`
      SELECT "variant" FROM "FeedExperimentAssignment"
      WHERE "userId" = ${userId} AND "experimentKey" = ${key}
      LIMIT 1
    `;
    const existing = rows[0]?.variant;
    if (existing === 'v1' || existing === 'v2' || existing === 'v2-shadow') {
      return existing;
    }

    const bucket = this.bucketFor(userId, key);
    const variant: FeedVariant = bucket < 10 ? 'v1' : bucket < 30 ? 'v2-shadow' : 'v2';
    await this.prisma.$executeRaw`
      INSERT INTO "FeedExperimentAssignment" ("userId","experimentKey","variant","assignedAt")
      VALUES (${userId}, ${key}, ${variant}, NOW())
      ON CONFLICT ("userId","experimentKey")
      DO NOTHING
    `;
    const persisted = await this.prisma.$queryRaw<Array<{ variant: string }>>`
      SELECT "variant" FROM "FeedExperimentAssignment"
      WHERE "userId" = ${userId} AND "experimentKey" = ${key}
      LIMIT 1
    `;
    const persistedVariant = persisted[0]?.variant;
    if (persistedVariant === 'v1' || persistedVariant === 'v2' || persistedVariant === 'v2-shadow') {
      return persistedVariant;
    }
    return variant;
  }

  private bucketFor(userId: string, key: string): number {
    const digest = createHash('sha256').update(`${userId}:${key}`).digest();
    return digest[0] % 100;
  }
}
