import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditService } from '../../audit/services/audit.service';
import type { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import {
  audienceFromApi,
  newBroadcastCampaignId,
  parseOptionalDate,
  toApiCampaign,
} from './admin-broadcasts.mapper';
import type {
  BroadcastCampaign,
  CreateBroadcastInput,
  UpdateBroadcastInput,
} from '../types/admin-broadcasts.types';

export type { BroadcastCampaign, CreateBroadcastInput, UpdateBroadcastInput } from '../types/admin-broadcasts.types';

@Injectable()
export class AdminBroadcastsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit?: AuditService,
  ) {}

  private assertEditable(campaign: BroadcastCampaign): void {
    if (campaign.status === 'sent' || campaign.status === 'cancelled') {
      throw new BadRequestException({
        code: 'BROADCAST_SENT_IMMUTABLE',
        message:
          campaign.status === 'sent'
            ? 'Sent campaigns cannot be modified'
            : 'Cancelled campaigns cannot be modified',
      });
    }
  }

  private assertDeletable(campaign: BroadcastCampaign): void {
    if (campaign.status === 'sent') {
      throw new BadRequestException({
        code: 'BROADCAST_SENT_IMMUTABLE',
        message: 'Sent campaigns cannot be deleted',
      });
    }
  }

  async list(): Promise<BroadcastCampaign[]> {
    const rows = await this.prisma.broadcastCampaign.findMany({
      orderBy: { createdAt: 'desc' },
    });
    return rows.map(toApiCampaign);
  }

  async getById(id: string): Promise<BroadcastCampaign> {
    const row = await this.prisma.broadcastCampaign.findUnique({ where: { id } });
    if (!row) {
      throw new NotFoundException({
        code: 'BROADCAST_CAMPAIGN_NOT_FOUND',
        message: 'Broadcast campaign not found',
      });
    }
    return toApiCampaign(row);
  }

  async create(input: CreateBroadcastInput, actor?: AuthenticatedUser): Promise<BroadcastCampaign> {
    const title = input.title.trim();
    const body = input.body.trim();
    if (!title || !body) {
      throw new BadRequestException({
        code: 'BROADCAST_TITLE_BODY_REQUIRED',
        message: 'Title and body are required',
      });
    }
    if (input.audience === 'users' && (!input.audienceUserIds || input.audienceUserIds.length === 0)) {
      throw new BadRequestException({
        code: 'BROADCAST_AUDIENCE_USERS_REQUIRED',
        message: 'At least one user ID is required for a specific audience',
      });
    }

    const scheduledAt = input.scheduledAt ? parseOptionalDate(input.scheduledAt) : undefined;
    const row = await this.prisma.broadcastCampaign.create({
      data: {
        id: newBroadcastCampaignId(),
        title,
        body,
        type: input.type?.trim() || 'SYSTEM',
        deeplink: input.deeplink?.trim() || null,
        audience: audienceFromApi(input.audience),
        audienceUserIds: input.audience === 'users' ? (input.audienceUserIds ?? []) : [],
        status: scheduledAt ? 'SCHEDULED' : 'DRAFT',
        scheduledAt: scheduledAt ?? null,
        createdById: actor?.userId ?? input.createdById ?? null,
      },
    });

    await this.audit?.log({
      actorId: actor?.userId ?? null,
      action: 'BROADCAST_CREATED',
      resourceType: 'BroadcastCampaign',
      resourceId: row.id,
      metadata: { audience: input.audience, status: row.status } as Prisma.InputJsonValue,
    });

    return toApiCampaign(row);
  }

  async update(id: string, input: UpdateBroadcastInput, actor?: AuthenticatedUser): Promise<BroadcastCampaign> {
    const current = await this.getById(id);
    this.assertEditable(current);

    const title = input.title?.trim() ?? current.title;
    const body = input.body?.trim() ?? current.body;
    if (!title || !body) {
      throw new BadRequestException({
        code: 'BROADCAST_TITLE_BODY_REQUIRED',
        message: 'Title and body are required',
      });
    }

    const audience = input.audience ?? current.audience;
    const audienceUserIds =
      input.audienceUserIds !== undefined ? input.audienceUserIds : current.audienceUserIds;
    if (audience === 'users' && (!audienceUserIds || audienceUserIds.length === 0)) {
      throw new BadRequestException({
        code: 'BROADCAST_AUDIENCE_USERS_REQUIRED',
        message: 'At least one user ID is required for a specific audience',
      });
    }

    let scheduledAt = current.scheduledAt ? new Date(current.scheduledAt) : null;
    if (input.scheduledAt !== undefined) {
      scheduledAt = parseOptionalDate(input.scheduledAt) ?? null;
    }

    let status = current.status;
    if (scheduledAt) {
      status = 'scheduled';
    } else if (current.status === 'scheduled') {
      status = 'draft';
    }

    const row = await this.prisma.broadcastCampaign.update({
      where: { id },
      data: {
        title,
        body,
        type: input.type?.trim() || current.type,
        deeplink: input.deeplink !== undefined ? input.deeplink?.trim() || null : current.deeplink ?? null,
        audience: audienceFromApi(audience),
        audienceUserIds: audience === 'users' ? (audienceUserIds ?? []) : [],
        scheduledAt,
        status: status === 'scheduled' ? 'SCHEDULED' : status === 'draft' ? 'DRAFT' : 'DRAFT',
      },
    });

    await this.audit?.log({
      actorId: actor?.userId ?? null,
      action: 'BROADCAST_UPDATED',
      resourceType: 'BroadcastCampaign',
      resourceId: id,
      metadata: { status: row.status } as Prisma.InputJsonValue,
    });

    return toApiCampaign(row);
  }

  async delete(id: string, actor?: AuthenticatedUser): Promise<void> {
    const current = await this.getById(id);
    this.assertDeletable(current);
    await this.prisma.broadcastCampaign.delete({ where: { id } });
    await this.audit?.log({
      actorId: actor?.userId ?? null,
      action: 'BROADCAST_DELETED',
      resourceType: 'BroadcastCampaign',
      resourceId: id,
    });
  }

  async cancel(id: string, actor?: AuthenticatedUser): Promise<BroadcastCampaign> {
    const current = await this.getById(id);
    if (current.status === 'sent') {
      throw new BadRequestException({
        code: 'BROADCAST_SENT_IMMUTABLE',
        message: 'Sent campaigns cannot be cancelled',
      });
    }
    if (current.status === 'cancelled') {
      return current;
    }

    const row = await this.prisma.broadcastCampaign.update({
      where: { id },
      data: { status: 'CANCELLED' },
    });

    await this.audit?.log({
      actorId: actor?.userId ?? null,
      action: 'BROADCAST_CANCELLED',
      resourceType: 'BroadcastCampaign',
      resourceId: id,
    });

    return toApiCampaign(row);
  }

  async claimForSend(id: string): Promise<BroadcastCampaign> {
    const claimed = await this.prisma.broadcastCampaign.updateMany({
      where: { id, status: { in: ['DRAFT', 'SCHEDULED'] } },
      data: {
        status: 'SENT',
        sentAt: new Date(),
        sentCount: 0,
      },
    });
    if (claimed.count === 0) {
      throw new NotFoundException({
        code: 'BROADCAST_NOT_SENDABLE',
        message: 'Campaign cannot be sent',
      });
    }
    return this.getById(id);
  }

  async updateSentCount(id: string, sentCount: number): Promise<BroadcastCampaign> {
    const row = await this.prisma.broadcastCampaign.update({
      where: { id },
      data: { sentCount, updatedAt: new Date() },
    });
    return toApiCampaign(row);
  }

  async listDueScheduled(limit = 10): Promise<BroadcastCampaign[]> {
    const rows = await this.prisma.broadcastCampaign.findMany({
      where: {
        status: 'SCHEDULED',
        scheduledAt: { lte: new Date() },
      },
      orderBy: { scheduledAt: 'asc' },
      take: limit,
    });
    return rows.map(toApiCampaign);
  }
}
