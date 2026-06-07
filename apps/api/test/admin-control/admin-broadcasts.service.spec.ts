/// <reference types="jest" />
import { BadRequestException, NotFoundException } from '@nestjs/common';
import {
  BroadcastAudience,
  BroadcastCampaignStatus,
} from '../../src/prisma-client';
import { AdminBroadcastsService } from '../../src/admin-control/services/admin-broadcasts.service';

type Row = {
  id: string;
  createdAt: Date;
  updatedAt: Date;
  title: string;
  body: string;
  type: string;
  deeplink: string | null;
  audience: BroadcastAudience;
  audienceUserIds: string[];
  status: BroadcastCampaignStatus;
  scheduledAt: Date | null;
  sentAt: Date | null;
  sentCount: number | null;
  createdById: string | null;
};

describe('AdminBroadcastsService', () => {
  let service: AdminBroadcastsService;
  let rows: Row[];
  let auditActions: string[];

  beforeEach(() => {
    rows = [];
    auditActions = [];
    const audit = {
      log: async ({ action }: { action: string }) => {
        auditActions.push(action);
      },
    };
    const prisma = {
      broadcastCampaign: {
        findMany: async ({
          where,
          orderBy,
          take,
        }: {
          where?: {
            status?: BroadcastCampaignStatus;
            scheduledAt?: { lte?: Date };
          };
          orderBy?: { createdAt?: 'desc'; scheduledAt?: 'asc' };
          take?: number;
        }) => {
          let filtered = rows.filter((row) => {
            if (where?.status && row.status !== where.status) return false;
            if (where?.scheduledAt?.lte && (!row.scheduledAt || row.scheduledAt > where.scheduledAt.lte)) {
              return false;
            }
            return true;
          });
          if (orderBy?.createdAt === 'desc') {
            filtered = [...filtered].sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
          }
          if (orderBy?.scheduledAt === 'asc') {
            filtered = [...filtered].sort(
              (a, b) => (a.scheduledAt?.getTime() ?? 0) - (b.scheduledAt?.getTime() ?? 0),
            );
          }
          if (take != null) filtered = filtered.slice(0, take);
          return filtered;
        },
        findUnique: async ({ where }: { where: { id: string } }) =>
          rows.find((row) => row.id === where.id) ?? null,
        create: async ({ data }: { data: Omit<Row, 'createdAt' | 'updatedAt'> & Partial<Pick<Row, 'createdAt' | 'updatedAt'>> }) => {
          const row: Row = {
            createdAt: data.createdAt ?? new Date(),
            updatedAt: data.updatedAt ?? new Date(),
            ...data,
          } as Row;
          rows.unshift(row);
          return row;
        },
        update: async ({
          where,
          data,
        }: {
          where: { id: string };
          data: Partial<Row>;
        }) => {
          const idx = rows.findIndex((row) => row.id === where.id);
          if (idx < 0) throw new Error('missing');
          rows[idx] = { ...rows[idx]!, ...data, updatedAt: new Date() };
          return rows[idx]!;
        },
        updateMany: async ({
          where,
          data,
        }: {
          where: { id?: string; status?: { in: BroadcastCampaignStatus[] } };
          data: Partial<Row>;
        }) => {
          let count = 0;
          rows = rows.map((row) => {
            const idOk = where.id == null || row.id === where.id;
            const statusOk =
              where.status?.in == null || where.status.in.includes(row.status);
            if (idOk && statusOk) {
              count += 1;
              return { ...row, ...data, updatedAt: new Date() };
            }
            return row;
          });
          return { count };
        },
        delete: async ({ where }: { where: { id: string } }) => {
          rows = rows.filter((row) => row.id !== where.id);
        },
      },
    };
    service = new AdminBroadcastsService(prisma as never, audit as never);
  });

  it('creates, updates, and deletes a draft campaign', async () => {
    const created = await service.create({
      title: 'Hello',
      body: 'World',
      type: 'SYSTEM',
      audience: 'all',
    });
    expect(created.status).toBe('draft');

    const updated = await service.update(created.id, { title: 'Updated title' });
    expect(updated.title).toBe('Updated title');

    await service.delete(created.id);
    await expect(service.getById(created.id)).rejects.toBeInstanceOf(NotFoundException);
    expect(auditActions).toEqual(
      expect.arrayContaining(['BROADCAST_CREATED', 'BROADCAST_UPDATED', 'BROADCAST_DELETED']),
    );
  });

  it('lists campaigns newest first', async () => {
    const first = await service.create({
      title: 'First',
      body: 'One',
      type: 'SYSTEM',
      audience: 'all',
    });
    await new Promise((resolve) => setTimeout(resolve, 5));
    const second = await service.create({
      title: 'Second',
      body: 'Two',
      type: 'SYSTEM',
      audience: 'all',
    });
    const list = await service.list();
    expect(list[0]?.id).toBe(second.id);
    expect(list[1]?.id).toBe(first.id);
  });

  it('rejects editing sent campaigns', async () => {
    const created = await service.create({
      title: 'Sent',
      body: 'Body',
      type: 'SYSTEM',
      audience: 'all',
    });
    await service.claimForSend(created.id);
    await service.updateSentCount(created.id, 3);
    await expect(service.update(created.id, { title: 'Nope' })).rejects.toBeInstanceOf(BadRequestException);
    await expect(service.delete(created.id)).rejects.toBeInstanceOf(BadRequestException);
  });

  it('claims only draft or scheduled campaigns for send', async () => {
    const created = await service.create({
      title: 'Send me',
      body: 'Body',
      type: 'SYSTEM',
      audience: 'all',
    });
    const claimed = await service.claimForSend(created.id);
    expect(claimed.status).toBe('sent');
    await expect(service.claimForSend(created.id)).rejects.toBeInstanceOf(NotFoundException);
  });

  it('returns due scheduled campaigns', async () => {
    const due = await service.create({
      title: 'Due',
      body: 'Now',
      type: 'SYSTEM',
      audience: 'all',
      scheduledAt: new Date(Date.now() - 60_000).toISOString(),
    });
    await service.create({
      title: 'Future',
      body: 'Later',
      type: 'SYSTEM',
      audience: 'all',
      scheduledAt: new Date(Date.now() + 3600_000).toISOString(),
    });
    const list = await service.listDueScheduled();
    expect(list.map((row) => row.id)).toEqual([due.id]);
  });
});
