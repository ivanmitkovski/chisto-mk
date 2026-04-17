/// <reference types="jest" />

import { ConflictException, NotFoundException } from '@nestjs/common';
import {
  CleanupEventStatus,
  EcoEventLifecycleStatus,
  Role,
} from '../../src/prisma-client';
import type { AuthenticatedUser } from '../../src/auth/types/authenticated-user.type';
import { CleanupEventsService } from '../../src/cleanup-events/cleanup-events.service';

function actor(id: string): AuthenticatedUser {
  return {
    userId: id,
    email: `${id}@test.chisto.mk`,
    phoneNumber: '+38970000000',
    role: Role.ADMIN,
  };
}

describe('CleanupEventsService duplicate schedule', () => {
  let prisma: {
    site: { findUnique: jest.Mock };
    cleanupEvent: {
      findUnique: jest.Mock;
      create: jest.Mock;
      update: jest.Mock;
    };
    $transaction: jest.Mock;
  };
  let audit: { log: jest.Mock };
  let ecoEventPoints: { creditIfNew: jest.Mock };
  let uploads: { signUrls: jest.Mock; getPublicUrlsForKeys: jest.Mock };
  let cleanupEventsSse: { emitCleanupEventCreated: jest.Mock; emitCleanupEventUpdated: jest.Mock };
  let scheduleConflict: { findConflictingEvent: jest.Mock };
  let service: CleanupEventsService;

  beforeEach(() => {
    audit = { log: jest.fn().mockResolvedValue(undefined) };
    ecoEventPoints = { creditIfNew: jest.fn().mockResolvedValue(0) };
    uploads = {
      signUrls: jest.fn().mockResolvedValue([]),
      getPublicUrlsForKeys: jest.fn().mockReturnValue([]),
    };
    cleanupEventsSse = {
      emitCleanupEventCreated: jest.fn(),
      emitCleanupEventUpdated: jest.fn(),
    };
    scheduleConflict = { findConflictingEvent: jest.fn().mockResolvedValue(null) };
    prisma = {
      site: { findUnique: jest.fn().mockResolvedValue({ id: 'site-1' }) },
      cleanupEvent: {
        findUnique: jest.fn(),
        create: jest.fn().mockResolvedValue({ id: 'new-1' }),
        update: jest.fn(),
      },
      $transaction: jest.fn(async (fn: (tx: typeof prisma) => Promise<unknown>) => fn(prisma)),
    };
    prisma.cleanupEvent.findUnique.mockResolvedValue({
      id: 'new-1',
      title: 'Cleanup event',
      description: '',
      siteId: 'site-1',
      scheduledAt: new Date('2025-07-01T10:00:00.000Z'),
      endAt: null,
      completedAt: null,
      organizerId: null,
      participantCount: 0,
      status: CleanupEventStatus.APPROVED,
      lifecycleStatus: EcoEventLifecycleStatus.UPCOMING,
      recurrenceRule: null,
      recurrenceIndex: null,
      parentEventId: null,
      category: 'GENERAL_CLEANUP',
      scale: null,
      difficulty: null,
      gear: [],
      maxParticipants: null,
      checkInOpen: false,
      checkedInCount: 0,
      afterImageKeys: [],
      site: {
        id: 'site-1',
        latitude: 0,
        longitude: 0,
        description: null,
        status: 'ACTIVE',
      },
      organizer: null,
      _count: { seriesChildren: 0 },
    });
    service = new CleanupEventsService(
      prisma as never,
      audit as never,
      ecoEventPoints as never,
      uploads as never,
      cleanupEventsSse as never,
      scheduleConflict as never,
    );
  });

  it('throws ConflictException on create when conflict exists', async () => {
    scheduleConflict.findConflictingEvent.mockResolvedValue({
      id: 'existing',
      title: 'Busy',
      scheduledAt: new Date('2025-07-01T10:00:00.000Z'),
    });
    await expect(
      service.create(
        {
          siteId: 'site-1',
          scheduledAt: '2025-07-01T11:00:00.000Z',
        },
        actor('admin-1'),
      ),
    ).rejects.toBeInstanceOf(ConflictException);
    expect(prisma.cleanupEvent.create).not.toHaveBeenCalled();
  });

  it('creates when no conflict', async () => {
    await service.create(
      {
        siteId: 'site-1',
        scheduledAt: '2025-07-01T11:00:00.000Z',
      },
      actor('admin-1'),
    );
    expect(prisma.cleanupEvent.create).toHaveBeenCalled();
 });

  it('patch scheduledAt uses excludeEventId', async () => {
    const patchRow = {
      id: 'evt-1',
      siteId: 'site-1',
      status: CleanupEventStatus.APPROVED,
      organizerId: 'o1',
      scheduledAt: new Date('2025-06-01T10:00:00.000Z'),
      endAt: null,
    };
    prisma.cleanupEvent.findUnique
      .mockResolvedValueOnce(patchRow)
      .mockResolvedValueOnce({
        ...patchRow,
        title: 'Cleanup event',
        description: '',
        completedAt: null,
        participantCount: 0,
        lifecycleStatus: EcoEventLifecycleStatus.UPCOMING,
        recurrenceRule: null,
        recurrenceIndex: null,
        parentEventId: null,
        category: 'GENERAL_CLEANUP',
        scale: null,
        difficulty: null,
        gear: [],
        maxParticipants: null,
        checkInOpen: false,
        checkedInCount: 0,
        afterImageKeys: [],
        scheduledAt: new Date('2025-08-01T12:00:00.000Z'),
        site: {
          id: 'site-1',
          latitude: 0,
          longitude: 0,
          description: null,
          status: 'ACTIVE',
        },
        organizer: null,
        _count: { seriesChildren: 0 },
      });
    scheduleConflict.findConflictingEvent.mockResolvedValue(null);
    prisma.cleanupEvent.update.mockResolvedValue({});

    await service.patch(
      'evt-1',
      { scheduledAt: '2025-08-01T12:00:00.000Z' },
      actor('admin-1'),
    );

    expect(scheduleConflict.findConflictingEvent).toHaveBeenCalledWith(
      expect.objectContaining({
        siteId: 'site-1',
        excludeEventId: 'evt-1',
      }),
    );
  });

  it('patch throws when schedule conflicts', async () => {
    prisma.cleanupEvent.findUnique.mockResolvedValue({
      id: 'evt-1',
      siteId: 'site-1',
      status: CleanupEventStatus.APPROVED,
      organizerId: 'o1',
      scheduledAt: new Date('2025-06-01T10:00:00.000Z'),
      endAt: null,
    });
    scheduleConflict.findConflictingEvent.mockResolvedValue({
      id: 'x',
      title: 'Y',
      scheduledAt: new Date('2025-08-01T10:00:00.000Z'),
    });
    await expect(
      service.patch('evt-1', { scheduledAt: '2025-08-01T12:00:00.000Z' }, actor('admin-1')),
    ).rejects.toBeInstanceOf(ConflictException);
    expect(prisma.$transaction).not.toHaveBeenCalled();
  });

  it('create throws NotFound when site missing', async () => {
    prisma.site.findUnique.mockResolvedValue(null);
    await expect(
      service.create({ siteId: 'nope', scheduledAt: '2025-07-01T10:00:00.000Z' }, actor('a')),
    ).rejects.toBeInstanceOf(NotFoundException);
  });
});
