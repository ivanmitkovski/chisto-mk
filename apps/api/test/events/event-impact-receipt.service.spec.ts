/// <reference types="jest" />

import { BadRequestException, NotFoundException } from '@nestjs/common';
import type { AuthenticatedUser } from '../../src/auth/types/authenticated-user.type';
import { Role } from '../../src/prisma-client';
import { EventImpactReceiptService } from '../../src/events/event-impact-receipt.service';
import { EventsTelemetryService } from '../../src/events/events-telemetry.service';
import { EcoEventLifecycleStatus, EventEvidenceKind } from '../../src/prisma-client';

function user(id: string): AuthenticatedUser {
  return {
    userId: id,
    email: `${id}@test.chisto.mk`,
    phoneNumber: '+38970000000',
    role: Role.USER,
  };
}

describe('EventImpactReceiptService', () => {
  const findFirst = jest.fn();
  const signUrls = jest.fn();
  const getPublicUrlsForKeys = jest.fn();
  const prisma = { cleanupEvent: { findFirst } } as never;
  const uploads = { signUrls, getPublicUrlsForKeys } as never;
  const telemetry = { emitSpan: jest.fn() } as unknown as EventsTelemetryService;

  let service: EventImpactReceiptService;

  beforeEach(() => {
    findFirst.mockReset();
    signUrls.mockReset();
    getPublicUrlsForKeys.mockReset();
    (telemetry.emitSpan as jest.Mock).mockReset();
    signUrls.mockImplementation(async (urls: string[]) => urls);
    getPublicUrlsForKeys.mockImplementation((keys: string[]) => keys.map((k) => `pub:${k}`));
    service = new EventImpactReceiptService(prisma, uploads as never, telemetry);
  });

  it('throws NotFound when event is missing', async () => {
    findFirst.mockResolvedValue(null);

    await expect(service.buildForViewer('e1', user('u1'))).rejects.toBeInstanceOf(NotFoundException);
  });

  it('throws BadRequest for UPCOMING', async () => {
    findFirst.mockResolvedValue({
      id: 'e1',
      title: 'T',
      scheduledAt: new Date(),
      endAt: null,
      lifecycleStatus: EcoEventLifecycleStatus.UPCOMING,
      participantCount: 0,
      checkedInCount: 0,
      afterImageKeys: [],
      site: { address: 'A', description: null },
      organizer: { firstName: 'O', lastName: 'r' },
      liveMetric: null,
      evidencePhotos: [],
      _count: { evidencePhotos: 0 },
    });

    try {
      await service.buildForViewer('e1', user('u1'));
      fail('expected BadRequestException');
    } catch (e) {
      expect(e).toBeInstanceOf(BadRequestException);
      const body = (e as BadRequestException).getResponse() as { code?: string };
      expect(body.code).toBe('EVENTS_IMPACT_RECEIPT_NOT_AVAILABLE');
    }
  });

  it('returns receipt for IN_PROGRESS with in_progress completeness', async () => {
    findFirst.mockResolvedValue({
      id: 'e1',
      title: 'River',
      scheduledAt: new Date('2026-06-01T08:00:00.000Z'),
      endAt: new Date('2026-06-01T10:00:00.000Z'),
      lifecycleStatus: EcoEventLifecycleStatus.IN_PROGRESS,
      participantCount: 5,
      checkedInCount: 2,
      afterImageKeys: [],
      site: { address: 'Skopje', description: null },
      organizer: { firstName: 'A', lastName: 'B' },
      liveMetric: { reportedBagsCollected: 3, updatedAt: new Date('2026-06-01T09:00:00.000Z') },
      evidencePhotos: [
        {
          id: 'p1',
          kind: EventEvidenceKind.FIELD,
          objectKey: 'k1',
          caption: null,
          createdAt: new Date('2026-06-01T08:30:00.000Z'),
        },
      ],
      _count: { evidencePhotos: 1 },
    });

    const dto = await service.buildForViewer('e1', user('u1'));

    expect(dto.lifecycleStatus).toBe('inProgress');
    expect(dto.completeness).toBe('in_progress');
    expect(dto.checkedInCount).toBe(2);
    expect(dto.reportedBagsCollected).toBe(3);
    expect(dto.evidence).toHaveLength(1);
    expect(dto.evidence[0]!.kind).toBe('field');
    expect(telemetry.emitSpan).toHaveBeenCalledWith(
      'events.impact_receipt.fetch',
      expect.objectContaining({ eventId: 'e1', lifecycle: 'inProgress', completeness: 'in_progress' }),
    );
  });

  it('returns full completeness when completed with after images and evidence', async () => {
    findFirst.mockResolvedValue({
      id: 'e2',
      title: 'Done',
      scheduledAt: new Date('2026-06-02T08:00:00.000Z'),
      endAt: new Date('2026-06-02T10:00:00.000Z'),
      lifecycleStatus: EcoEventLifecycleStatus.COMPLETED,
      participantCount: 10,
      checkedInCount: 8,
      afterImageKeys: ['a1'],
      site: { address: '', description: 'Park' },
      organizer: { firstName: 'X', lastName: 'Y' },
      liveMetric: { reportedBagsCollected: 12, updatedAt: new Date('2026-06-02T11:00:00.000Z') },
      evidencePhotos: [
        {
          id: 'p2',
          kind: EventEvidenceKind.AFTER,
          objectKey: 'k2',
          caption: 'c',
          createdAt: new Date('2026-06-02T10:00:00.000Z'),
        },
      ],
      _count: { evidencePhotos: 1 },
    });

    const dto = await service.buildForViewer('e2', user('u1'));

    expect(dto.completeness).toBe('full');
    expect(dto.afterImageUrls).toHaveLength(1);
    expect(dto.organizerName).toBe('X Y');
    expect(dto.siteLabel).toBe('Park');
  });
});
