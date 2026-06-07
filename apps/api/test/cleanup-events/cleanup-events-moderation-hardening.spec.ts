/// <reference types="jest" />

import { BadRequestException } from '@nestjs/common';
import { CleanupEventStatus, EcoEventLifecycleStatus, Role } from '../../src/prisma-client';
import type { AuthenticatedUser } from '../../src/auth/types/authenticated-user.type';
import { CleanupEventsModerationNotesService } from '../../src/cleanup-events/services/cleanup-events-moderation-notes.service';
import { CleanupEventsParticipantsAdminService } from '../../src/cleanup-events/services/cleanup-events-participants-admin.service';
import { CleanupEventsCheckInRiskSignalsService } from '../../src/cleanup-events/services/cleanup-events-check-in-risk-signals.service';

function actor(id: string): AuthenticatedUser {
  return {
    userId: id,
    email: `${id}@test.chisto.mk`,
    phoneNumber: '+38970000000',
    role: Role.ADMIN,
  };
}

describe('CleanupEventsModerationNotesService', () => {
  it('creates and lists notes', async () => {
    const prisma = {
      cleanupEvent: {
        findUnique: jest.fn().mockResolvedValue({ id: 'evt-1' }),
      },
      cleanupEventModerationNote: {
        findMany: jest.fn().mockResolvedValue([
          {
            id: 'note-1',
            createdAt: new Date('2025-01-02T00:00:00.000Z'),
            updatedAt: new Date('2025-01-02T00:00:00.000Z'),
            body: 'Needs site review',
            authorEmailSnapshot: 'admin@test.chisto.mk',
            authorId: 'admin-1',
            author: { id: 'admin-1', email: 'admin@test.chisto.mk' },
          },
        ]),
        create: jest.fn().mockResolvedValue({
          id: 'note-2',
          createdAt: new Date('2025-01-03T00:00:00.000Z'),
          updatedAt: new Date('2025-01-03T00:00:00.000Z'),
          body: 'Follow up',
          authorEmailSnapshot: 'admin@test.chisto.mk',
          authorId: 'admin-1',
          author: { id: 'admin-1', email: 'admin@test.chisto.mk' },
        }),
        findFirst: jest.fn(),
        delete: jest.fn(),
      },
    };
    const audit = { log: jest.fn().mockResolvedValue(undefined) };
    const service = new CleanupEventsModerationNotesService(prisma as never, audit as never);

    const listed = await service.listNotes('evt-1');
    expect(listed.data).toHaveLength(1);

    const created = await service.createNote('evt-1', { body: 'Follow up' }, actor('admin-1'));
    expect(created.body).toBe('Follow up');
    expect(audit.log).toHaveBeenCalledWith(
      expect.objectContaining({ action: 'CLEANUP_EVENT_NOTE_ADDED' }),
    );
  });
});

describe('CleanupEventsParticipantsAdminService', () => {
  it('removes participant and decrements count', async () => {
    const prisma: {
      cleanupEvent: {
        findUnique: jest.Mock;
        update: jest.Mock;
      };
      eventParticipant: {
        findUnique: jest.Mock;
        delete: jest.Mock;
      };
      $transaction: jest.Mock;
    } = {
      cleanupEvent: {
        findUnique: jest.fn().mockResolvedValue({ id: 'evt-1', participantCount: 3 }),
        update: jest.fn(),
      },
      eventParticipant: {
        findUnique: jest.fn().mockResolvedValue({ id: 'part-1' }),
        delete: jest.fn(),
      },
      $transaction: jest.fn(async (fn: (tx: unknown) => Promise<unknown>) => fn(prisma)),
    };
    const audit = { log: jest.fn().mockResolvedValue(undefined) };
    const list = { findOne: jest.fn().mockResolvedValue({ id: 'evt-1', participantCount: 2 }) };
    const service = new CleanupEventsParticipantsAdminService(
      prisma as never,
      audit as never,
      list as never,
    );

    const out = await service.removeParticipant('evt-1', 'user-1', actor('admin-1'));
    expect(out.participantCount).toBe(2);
    expect(prisma.cleanupEvent.update).toHaveBeenCalledWith({
      where: { id: 'evt-1' },
      data: { participantCount: 2 },
    });
  });
});

describe('CleanupEventsCheckInRiskSignalsService eventId filter', () => {
  it('passes eventId into list where clause', async () => {
    const prisma = {
      checkInRiskSignal: {
        findMany: jest.fn().mockResolvedValue([]),
        count: jest.fn().mockResolvedValue(0),
      },
    };
    const realtime = { emitUpdated: jest.fn() };
    const service = new CleanupEventsCheckInRiskSignalsService(prisma as never, realtime as never);

    await service.listCheckInRiskSignals({
      page: 1,
      limit: 10,
      status: 'all',
      eventId: 'evt-abc',
    });

    expect(prisma.checkInRiskSignal.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({ eventId: 'evt-abc' }),
      }),
    );
  });
});

describe('Patch moderation return-to-pending guard', () => {
  it('rejects return-to-pending from PENDING status', async () => {
    const { CleanupEventsPatchMutationService } = await import(
      '../../src/cleanup-events/services/cleanup-events-mutation-patch.service'
    );
    const prisma = {
      cleanupEvent: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'evt-1',
          siteId: 'site-1',
          status: CleanupEventStatus.PENDING,
          lifecycleStatus: EcoEventLifecycleStatus.UPCOMING,
          scheduledAt: new Date('2025-07-01T10:00:00.000Z'),
          endAt: null,
          organizerId: null,
        }),
        update: jest.fn(),
      },
      $transaction: jest.fn(),
    };
    const service = new CleanupEventsPatchMutationService(
      prisma as never,
      { log: jest.fn() } as never,
      { creditIfNew: jest.fn() } as never,
      { emitCleanupEventUpdated: jest.fn() } as never,
      { findConflictingEvent: jest.fn() } as never,
      {
        notifyAudienceEventPublished: jest.fn(),
        notifyOrganizerApproved: jest.fn(),
        notifyOrganizerDeclined: jest.fn(),
        notifyOrganizerReturnedToPending: jest.fn(),
      } as never,
      { findOne: jest.fn() } as never,
    );

    await expect(
      service.patch('evt-1', { status: CleanupEventStatus.PENDING }, actor('admin-1')),
    ).rejects.toBeInstanceOf(BadRequestException);
  });
});
