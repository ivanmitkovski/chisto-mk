/// <reference types="jest" />

import { NotFoundException } from '@nestjs/common';
import { EcoEventLifecycleStatus } from '../../src/prisma-client';
import { EventsQueryService } from '../../src/events/events-query.service';
import { EventsRepository } from '../../src/events/events.repository';
import type { PrismaService } from '../../src/prisma/prisma.service';
import type { ReportsUploadService } from '../../src/reports/reports-upload.service';
import type { EventsMobileMapperService } from '../../src/events/events-mobile-mapper.service';
import type { EventScheduleConflictService } from '../../src/event-schedule-conflict/event-schedule-conflict.service';
import type { EventsTelemetryService } from '../../src/events/events-telemetry.service';

describe('EventsQueryService.findPublicShareCard', () => {
  function buildService(prisma: Pick<PrismaService, 'cleanupEvent'>): EventsQueryService {
    const repo = { prisma } as EventsRepository;
    return new EventsQueryService(
      repo,
      {} as ReportsUploadService,
      {} as EventsMobileMapperService,
      {} as EventScheduleConflictService,
      {} as EventsTelemetryService,
    );
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
