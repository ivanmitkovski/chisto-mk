/// <reference types="jest" />

import { NotFoundException } from '@nestjs/common';
import { EcoEventLifecycleStatus } from '../../src/prisma-client';
import { EventsRepository } from '../../src/events/events.repository';
import { EventsShareCardQueryService } from '../../src/events/events-share-card-query.service';
import type { PrismaService } from '../../src/prisma/prisma.service';

describe('EventsShareCardQueryService.findPublicShareCard', () => {
  function buildService(prisma: Pick<PrismaService, 'cleanupEvent'>): EventsShareCardQueryService {
    const repo = { prisma } as EventsRepository;
    return new EventsShareCardQueryService(repo);
  }

  it('throws NotFound when event is missing or not shareable', async () => {
    const prisma = {
      cleanupEvent: { findFirst: jest.fn().mockResolvedValue(null) },
    } as unknown as PrismaService;
    const svc = buildService(prisma);

    await expect(svc.findPublicShareCard('missing-id')).rejects.toBeInstanceOf(NotFoundException);
  });

  it('returns share payload with address-based site label', async () => {
    const prisma = {
      cleanupEvent: {
        findFirst: jest.fn().mockResolvedValue({
          id: 'evt1',
          title: 'River cleanup',
          scheduledAt: new Date('2026-06-01T08:00:00.000Z'),
          endAt: null,
          lifecycleStatus: EcoEventLifecycleStatus.UPCOMING,
          site: { address: 'Skopje', description: 'Riverside' },
        }),
      },
    } as unknown as PrismaService;
    const svc = buildService(prisma);

    const card = await svc.findPublicShareCard('evt1');

    expect(card).toEqual({
      id: 'evt1',
      title: 'River cleanup',
      siteLabel: 'Skopje',
      scheduledAt: '2026-06-01T08:00:00.000Z',
      endAt: null,
      lifecycleStatus: EcoEventLifecycleStatus.UPCOMING,
    });
  });
});
