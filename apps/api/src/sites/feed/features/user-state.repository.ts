import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';
import type { FeedUserState } from '../feed-v2.types';
import { RedisFeedStateAdapter } from './redis-feed-state.adapter';

@Injectable()
export class UserStateRepository {
  private readonly cache = new Map<string, { value: FeedUserState; expiresAt: number }>();
  private readonly ttlMs = 24 * 60 * 60 * 1000;

  constructor(
    private readonly prisma: PrismaService,
    private readonly redisFeedState: RedisFeedStateAdapter,
  ) {}

  async getState(userId: string): Promise<FeedUserState> {
    const now = Date.now();
    const redisState = await this.redisFeedState.getJson<{
      hiddenSiteIds: string[];
      mutedCategoryIds: string[];
      followReporterIds: string[];
    }>(`user:${userId}:state`);
    const seenFromRedis = await this.redisFeedState.zRangeSeen(
      `user:${userId}:seen`,
      Date.now() - 24 * 60 * 60 * 1000,
    );
    const hit = this.cache.get(userId);
    if (hit && hit.expiresAt > now) {
      for (const [siteId, seenAtMs] of seenFromRedis) {
        hit.value.seenSiteIds.set(siteId, seenAtMs);
      }
      return hit.value;
    }

    const rows = await this.prisma.$queryRaw<
      Array<{
        hiddenSiteIds: string[] | null;
        mutedCategoryIds: string[] | null;
        followReporterIds: string[] | null;
      }>
    >`SELECT "hiddenSiteIds", "mutedCategoryIds", "followReporterIds" FROM "UserFeedState" WHERE "userId" = ${userId} LIMIT 1`;
    const state: FeedUserState = {
      hiddenSiteIds: new Set(redisState?.hiddenSiteIds ?? rows[0]?.hiddenSiteIds ?? []),
      mutedCategoryIds: new Set(redisState?.mutedCategoryIds ?? rows[0]?.mutedCategoryIds ?? []),
      followReporterIds: new Set(redisState?.followReporterIds ?? rows[0]?.followReporterIds ?? []),
      seenSiteIds: new Map<string, number>(seenFromRedis),
    };
    await this.redisFeedState.setJson(
      `user:${userId}:state`,
      {
        hiddenSiteIds: [...state.hiddenSiteIds],
        mutedCategoryIds: [...state.mutedCategoryIds],
        followReporterIds: [...state.followReporterIds],
      },
      24 * 60 * 60,
    );
    this.cache.set(userId, { value: state, expiresAt: now + this.ttlMs });
    return state;
  }

  async cacheSeen(userId: string, siteId: string, seenAtMs: number): Promise<void> {
    const hit = this.cache.get(userId);
    if (hit) {
      hit.value.seenSiteIds.set(siteId, seenAtMs);
    }
    await this.redisFeedState.zAddSeen(`user:${userId}:seen`, siteId, seenAtMs, 24 * 60 * 60);
  }
}
