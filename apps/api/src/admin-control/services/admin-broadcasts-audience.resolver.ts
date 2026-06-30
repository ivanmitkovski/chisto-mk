import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import type { BroadcastCampaign } from '../types/admin-broadcasts.types';

export const BROADCAST_RECIPIENT_CAP = 5000;
export const BROADCAST_AUDIENCE_LOOKUP_MAX = 100;

const ACTIVE_WITHIN_MS = 30 * 86400000;

type AudienceInput = Pick<BroadcastCampaign, 'audience' | 'audienceUserIds'>;

@Injectable()
export class AdminBroadcastsAudienceResolver {
  constructor(private readonly prisma: PrismaService) {}

  async resolveAudienceUserIds(campaign: AudienceInput): Promise<string[]> {
    if (campaign.audience === 'users' && campaign.audienceUserIds?.length) {
      const users = await this.prisma.user.findMany({
        where: {
          id: { in: campaign.audienceUserIds },
          status: 'ACTIVE',
        },
        select: { id: true },
      });
      const activeIds = new Set(users.map((user) => user.id));
      return campaign.audienceUserIds.filter((id) => activeIds.has(id));
    }

    const where =
      campaign.audience === 'active'
        ? {
            status: 'ACTIVE' as const,
            lastActiveAt: { gte: new Date(Date.now() - ACTIVE_WITHIN_MS) },
          }
        : { status: 'ACTIVE' as const };

    const users = await this.prisma.user.findMany({
      where,
      select: { id: true },
      take: BROADCAST_RECIPIENT_CAP,
    });
    return users.map((user) => user.id);
  }

  async countAudience(
    campaign: AudienceInput,
  ): Promise<{ recipientCount: number; capped: boolean; cap: number }> {
    const cap = BROADCAST_RECIPIENT_CAP;

    if (campaign.audience === 'users') {
      const ids = await this.resolveAudienceUserIds(campaign);
      return { recipientCount: ids.length, capped: false, cap };
    }

    const where =
      campaign.audience === 'active'
        ? {
            status: 'ACTIVE' as const,
            lastActiveAt: { gte: new Date(Date.now() - ACTIVE_WITHIN_MS) },
          }
        : { status: 'ACTIVE' as const };

    const total = await this.prisma.user.count({ where });
    return {
      recipientCount: Math.min(total, cap),
      capped: total > cap,
      cap,
    };
  }

  async lookupUsers(userIds: string[]) {
    const unique = [...new Set(userIds.map((id) => id.trim()).filter(Boolean))].slice(
      0,
      BROADCAST_AUDIENCE_LOOKUP_MAX,
    );
    if (unique.length === 0) {
      return [];
    }
    return this.prisma.user.findMany({
      where: { id: { in: unique } },
      select: {
        id: true,
        firstName: true,
        lastName: true,
        email: true,
        phoneNumber: true,
        status: true,
      },
    });
  }

  async validateAudienceUserIds(userIds: string[]): Promise<string[]> {
    const unique = [...new Set(userIds.map((id) => id.trim()).filter(Boolean))];
    if (unique.length === 0) {
      throw new BadRequestException({
        code: 'BROADCAST_AUDIENCE_USERS_REQUIRED',
        message: 'At least one user ID is required for a specific audience',
      });
    }

    const users = await this.prisma.user.findMany({
      where: { id: { in: unique } },
      select: { id: true, status: true },
    });
    const foundIds = new Set(users.map((user) => user.id));
    const invalidIds = unique.filter((id) => !foundIds.has(id));
    if (invalidIds.length > 0) {
      throw new BadRequestException({
        code: 'BROADCAST_INVALID_USER_IDS',
        message: 'One or more user IDs are invalid',
        invalidIds,
      });
    }

    const ineligibleIds = users.filter((user) => user.status !== 'ACTIVE').map((user) => user.id);
    if (ineligibleIds.length > 0) {
      throw new BadRequestException({
        code: 'BROADCAST_INELIGIBLE_USERS',
        message: 'One or more users cannot receive broadcasts',
        ineligibleIds,
      });
    }

    return unique;
  }
}
