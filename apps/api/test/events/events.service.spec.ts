/// <reference types="jest" />

import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import {
  CleanupEventStatus,
  EcoEventCategory,
  EcoEventLifecycleStatus,
  NotificationType,
  Role,
} from '../../src/prisma-client';
import type { AuthenticatedUser } from '../../src/auth/types/authenticated-user.type';
import { CheckEventConflictQueryDto } from '../../src/events/dto/check-event-conflict-query.dto';
import { ListEventParticipantsQueryDto } from '../../src/events/dto/list-event-participants-query.dto';
import { ListEventsQueryDto } from '../../src/events/dto/list-events-query.dto';
import { PatchEventReminderDto } from '../../src/events/dto/patch-event-reminder.dto';
import { EventsCreationService } from '../../src/events/events-creation.service';
import { EventsLifecycleParticipationService } from '../../src/events/events-lifecycle-participation.service';
import { EventsMobileMapperService } from '../../src/events/events-mobile-mapper.service';
import { EventsQueryService } from '../../src/events/events-query.service';
import { EventsRepository } from '../../src/events/events.repository';
import { EventsService } from '../../src/events/events.service';
import { EventsUpdateService } from '../../src/events/events-update.service';

function user(id: string, role: Role = Role.USER): AuthenticatedUser {
  return {
    userId: id,
    email: `${id}@test.chisto.mk`,
    phoneNumber: '+38970000000',
    role,
  };
}

function makeUploads() {
  return {
    signUrls: jest.fn(async (urls: string[]) => urls),
    getPublicUrlsForKeys: jest.fn((keys: string[]) =>
      keys.map((k) => `https://bucket.s3.eu-central-1.amazonaws.com/${k}`),
    ),
    signPrivateObjectKey: jest.fn().mockResolvedValue(null),
  };
}

function makeCleanupMediaUpload() {
  return {
    uploadCleanupEventAfterImages: jest.fn(),
  };
}

function baseEvent(overrides: Partial<Record<string, unknown>> = {}) {
  return {
    id: 'evt-1',
    createdAt: new Date('2025-01-01T10:00:00Z'),
    updatedAt: new Date('2025-01-01T10:00:00Z'),
    siteId: 'site-1',
    title: 'River cleanup',
    description: 'Desc',
    category: EcoEventCategory.RIVER_AND_LAKE,
    scheduledAt: new Date('2025-06-01T09:00:00Z'),
    endAt: null,
    completedAt: null,
    status: CleanupEventStatus.APPROVED,
    lifecycleStatus: EcoEventLifecycleStatus.UPCOMING,
    organizerId: 'org-1',
    participantCount: 2,
    gear: [] as string[],
    scale: null,
    difficulty: null,
    afterImageKeys: [] as string[],
    maxParticipants: 50,
    site: {
      id: 'site-1',
      address: 'Skopje',
      description: null,
      latitude: 42.0,
      longitude: 21.4,
      reports: [] as { mediaUrls: string[] }[],
    },
    organizer: {
      id: 'org-1',
      firstName: 'Org',
      lastName: 'User',
      avatarObjectKey: null as string | null,
    },
    participants: [] as { id: string; reminderEnabled: boolean; reminderAt: Date | null }[],
    checkIns: [] as { checkedInAt: Date }[],
    liveMetric: null as { reportedBagsCollected: number; updatedAt: Date } | null,
    routeSegments: [] as unknown[],
    evidencePhotos: [] as unknown[],
    checkInSessionId: null,
    checkInOpen: false,
    checkedInCount: 0,
    recurrenceRule: null,
    parentEventId: null,
    recurrenceIndex: null,
    ...overrides,
  };
}

describe('EventsService', () => {
  let prisma: {
    site: { findUnique: jest.Mock };
    user: { findUnique: jest.Mock };
    cleanupEvent: {
      findMany: jest.Mock;
      findFirst: jest.Mock;
      findUnique: jest.Mock;
      findFirstOrThrow: jest.Mock;
      create: jest.Mock;
      update: jest.Mock;
    };
    eventParticipant: {
      create: jest.Mock;
      deleteMany: jest.Mock;
      findMany: jest.Mock;
      findUnique: jest.Mock;
      update: jest.Mock;
    };
    eventCheckIn: { findMany: jest.Mock; count: jest.Mock };
    pointTransaction: { findMany: jest.Mock };
    userDeviceToken: { findMany: jest.Mock };
    $executeRaw: jest.Mock;
    $queryRaw: jest.Mock;
    $transaction: jest.Mock;
  };
  let uploads: ReturnType<typeof makeUploads>;
  let cleanupMediaUpload: ReturnType<typeof makeCleanupMediaUpload>;
  let ecoEventPoints: { creditIfNew: jest.Mock; debitOnceIfNew: jest.Mock };
  let notificationDispatcher: { dispatchToUser: jest.Mock };
  let cleanupEventNotifications: {
    notifyStaffPendingReview: jest.Mock;
    notifyAudienceEventPublished: jest.Mock;
    notifyOrganizerReturnedToPending: jest.Mock;
  };
  let eventChat: { createSystemMessage: jest.Mock };
  let cleanupEventsSse: {
    emitCleanupEventPending: jest.Mock;
    emitCleanupEventCreated: jest.Mock;
    emitCleanupEventUpdated: jest.Mock;
  };
  let scheduleConflict: { findConflictingEvent: jest.Mock };
  let routeSegments: { replaceWaypoints: jest.Mock };
  let liveImpact: { notifyListeners: jest.Mock };
  let service: EventsService;

  beforeEach(() => {
    uploads = makeUploads();
    cleanupMediaUpload = makeCleanupMediaUpload();
    ecoEventPoints = {
      creditIfNew: jest.fn().mockResolvedValue(0),
      debitOnceIfNew: jest.fn().mockResolvedValue(0),
    };
    notificationDispatcher = { dispatchToUser: jest.fn().mockResolvedValue(undefined) };
    cleanupEventNotifications = {
      notifyStaffPendingReview: jest.fn().mockResolvedValue(undefined),
      notifyAudienceEventPublished: jest.fn().mockResolvedValue(undefined),
      notifyOrganizerReturnedToPending: jest.fn().mockResolvedValue(undefined),
    };
    eventChat = { createSystemMessage: jest.fn().mockResolvedValue(undefined) };
    cleanupEventsSse = {
      emitCleanupEventPending: jest.fn(),
      emitCleanupEventCreated: jest.fn(),
      emitCleanupEventUpdated: jest.fn(),
    };
    scheduleConflict = {
      findConflictingEvent: jest.fn().mockResolvedValue(null),
    };
    routeSegments = { replaceWaypoints: jest.fn().mockResolvedValue([]) };
    liveImpact = { notifyListeners: jest.fn() };
    const eventsTelemetry = { emitSpan: jest.fn() };
    prisma = {
      site: { findUnique: jest.fn() },
      user: {
        findUnique: jest.fn().mockResolvedValue({ organizerCertifiedAt: new Date('2026-01-01') }),
      },
      cleanupEvent: {
        findMany: jest.fn(),
        findFirst: jest.fn(),
        findUnique: jest.fn(),
        findFirstOrThrow: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
      },
      eventParticipant: {
        create: jest.fn(),
        deleteMany: jest.fn(),
        findMany: jest.fn(),
        findUnique: jest.fn(),
        update: jest.fn(),
      },
      eventCheckIn: {
        findMany: jest.fn().mockResolvedValue([]),
        count: jest.fn().mockResolvedValue(0),
      },
      pointTransaction: { findMany: jest.fn().mockResolvedValue([]) },
      userDeviceToken: { findMany: jest.fn().mockResolvedValue([]) },
      $executeRaw: jest.fn().mockResolvedValue(1),
      $queryRaw: jest.fn().mockResolvedValue([]),
      $transaction: jest.fn(async (arg: unknown) => {
        if (typeof arg === 'function') {
          return arg(prisma);
        }
        for (const op of arg as Array<Promise<unknown>>) {
          await op;
        }
      }),
    };
    const eventsRepository = new EventsRepository(prisma as never);
    const mobileMapper = new EventsMobileMapperService(eventsRepository, uploads as never);
    const query = new EventsQueryService(
      eventsRepository,
      uploads as never,
      mobileMapper,
      scheduleConflict as never,
      eventsTelemetry as never,
    );
    const creation = new EventsCreationService(
      eventsRepository,
      mobileMapper,
      cleanupEventsSse as never,
      cleanupEventNotifications as never,
      scheduleConflict as never,
      routeSegments as never,
    );
    const update = new EventsUpdateService(
      eventsRepository,
      mobileMapper,
      scheduleConflict as never,
      cleanupEventsSse as never,
      cleanupEventNotifications as never,
      eventChat as never,
      routeSegments as never,
    );
    const lifecycle = new EventsLifecycleParticipationService(
      eventsRepository,
      cleanupMediaUpload as never,
      mobileMapper,
      ecoEventPoints as never,
      notificationDispatcher as never,
      eventChat as never,
      liveImpact as never,
    );
    service = new EventsService(query, creation, update, lifecycle);
  });

  describe('create', () => {
    it('sets PENDING moderation for regular users', async () => {
      prisma.site.findUnique.mockResolvedValue({ id: 'site-1' });
      prisma.cleanupEvent.create.mockResolvedValue({ id: 'new-evt' });
      prisma.cleanupEvent.findFirstOrThrow.mockResolvedValue(baseEvent({ id: 'new-evt' }));

      await service.create(
        {
          siteId: 'site-1',
          title: 'My event',
          description: 'Hello world cleanup',
          category: 'generalCleanup',
          scheduledAt: '2025-07-01T10:00:00.000Z',
        },
        user('u1', Role.USER),
      );

      expect(prisma.cleanupEvent.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            status: CleanupEventStatus.PENDING,
            organizerId: 'u1',
          }),
        }),
      );
    });

    it('sets APPROVED moderation for admin', async () => {
      prisma.site.findUnique.mockResolvedValue({ id: 'site-1' });
      prisma.cleanupEvent.create.mockResolvedValue({ id: 'new-evt' });
      prisma.cleanupEvent.findFirstOrThrow.mockResolvedValue(
        baseEvent({ id: 'new-evt', status: CleanupEventStatus.APPROVED }),
      );

      await service.create(
        {
          siteId: 'site-1',
          title: 'Staff event',
          description: 'Hello world cleanup',
          category: 'generalCleanup',
          scheduledAt: '2025-07-01T10:00:00.000Z',
        },
        user('admin-1', Role.ADMIN),
      );

      expect(prisma.cleanupEvent.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            status: CleanupEventStatus.APPROVED,
          }),
        }),
      );
    });

    it('throws when site is missing', async () => {
      prisma.site.findUnique.mockResolvedValue(null);
      await expect(
        service.create(
          {
            siteId: 'missing',
            title: 'My event',
            description: 'Hello world cleanup',
            category: 'generalCleanup',
            scheduledAt: '2025-07-01T10:00:00.000Z',
          },
          user('u1'),
        ),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it('rejects invalid recurrenceRule', async () => {
      prisma.site.findUnique.mockResolvedValue({ id: 'site-1' });
      await expect(
        service.create(
          {
            siteId: 'site-1',
            title: 'Series',
            description: 'Hello world cleanup',
            category: 'generalCleanup',
            scheduledAt: '2025-07-01T10:00:00.000Z',
            recurrenceRule: 'INVALID_RRULE_SYNTAX',
          },
          user('u1'),
        ),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('throws ConflictException when another active event overlaps', async () => {
      prisma.site.findUnique.mockResolvedValue({ id: 'site-1' });
      scheduleConflict.findConflictingEvent.mockResolvedValue({
        id: 'other-evt',
        title: 'Existing cleanup',
        scheduledAt: new Date('2025-07-01T10:00:00.000Z'),
      });
      await expect(
        service.create(
          {
            siteId: 'site-1',
            title: 'My event',
            description: 'Hello world cleanup',
            category: 'generalCleanup',
            scheduledAt: '2025-07-01T10:30:00.000Z',
          },
          user('u1', Role.USER),
        ),
      ).rejects.toBeInstanceOf(ConflictException);
      expect(prisma.cleanupEvent.create).not.toHaveBeenCalled();
    });

    it('throws ConflictException on series when a later occurrence conflicts', async () => {
      prisma.site.findUnique.mockResolvedValue({ id: 'site-1' });
      let call = 0;
      scheduleConflict.findConflictingEvent.mockImplementation(async () => {
        call += 1;
        if (call >= 2) {
          return {
            id: 'blocker',
            title: 'Blocked day',
            scheduledAt: new Date('2025-07-03T10:00:00.000Z'),
          };
        }
        return null;
      });
      await expect(
        service.create(
          {
            siteId: 'site-1',
            title: 'Series',
            description: 'Hello world cleanup',
            category: 'generalCleanup',
            scheduledAt: '2025-07-01T10:00:00.000Z',
            recurrenceRule: 'FREQ=DAILY;COUNT=4',
            recurrenceCount: 4,
          },
          user('u1', Role.USER),
        ),
      ).rejects.toBeInstanceOf(ConflictException);
      expect(prisma.$transaction).not.toHaveBeenCalled();
    });

    it('accepts when endAt is on the same Skopje calendar day as scheduledAt', async () => {
      prisma.site.findUnique.mockResolvedValue({ id: 'site-1' });
      prisma.cleanupEvent.create.mockResolvedValue({ id: 'new-evt' });
      prisma.cleanupEvent.findFirstOrThrow.mockResolvedValue(baseEvent({ id: 'new-evt' }));
      scheduleConflict.findConflictingEvent.mockResolvedValue(null);

      await service.create(
        {
          siteId: 'site-1',
          title: 'Same day end',
          description: 'Hello world cleanup',
          category: 'generalCleanup',
          scheduledAt: '2025-07-01T08:00:00.000Z',
          endAt: '2025-07-01T20:00:00.000Z',
        },
        user('u1', Role.USER),
      );

      expect(prisma.cleanupEvent.create).toHaveBeenCalled();
    });

    it('rejects when endAt falls on the next Skopje calendar day', async () => {
      prisma.site.findUnique.mockResolvedValue({ id: 'site-1' });
      let thrown: unknown;
      try {
        await service.create(
          {
            siteId: 'site-1',
            title: 'Cross midnight Skopje',
            description: 'Hello world cleanup',
            category: 'generalCleanup',
            scheduledAt: '2025-07-01T20:00:00.000Z',
            endAt: '2025-07-01T22:30:00.000Z',
          },
          user('u1', Role.USER),
        );
      } catch (e) {
        thrown = e;
      }
      expect(thrown).toBeInstanceOf(BadRequestException);
      expect((thrown as BadRequestException).getResponse()).toEqual(
        expect.objectContaining({ code: 'EVENTS_END_DIFFERENT_SKOPJE_CALENDAR_DAY' }),
      );
    });
  });

  describe('checkScheduleConflictPreview', () => {
    it('returns hasConflict false when no overlap', async () => {
      const q = Object.assign(new CheckEventConflictQueryDto(), {
        siteId: 'site-1',
        scheduledAt: '2025-07-01T10:00:00.000Z',
      });
      const out = await service.checkScheduleConflictPreview(q);
      expect(out.hasConflict).toBe(false);
      expect(out.conflictingEvent).toBeUndefined();
    });

    it('returns conflictingEvent when overlap exists', async () => {
      scheduleConflict.findConflictingEvent.mockResolvedValue({
        id: 'e1',
        title: 'T',
        scheduledAt: new Date('2025-07-01T09:00:00.000Z'),
      });
      const q = Object.assign(new CheckEventConflictQueryDto(), {
        siteId: 'site-1',
        scheduledAt: '2025-07-01T10:00:00.000Z',
      });
      const out = await service.checkScheduleConflictPreview(q);
      expect(out.hasConflict).toBe(true);
      expect(out.conflictingEvent?.id).toBe('e1');
    });

    it('accepts preview when endAt is same Skopje calendar day as scheduledAt', async () => {
      const q = Object.assign(new CheckEventConflictQueryDto(), {
        siteId: 'site-1',
        scheduledAt: '2025-07-01T08:00:00.000Z',
        endAt: '2025-07-01T20:00:00.000Z',
      });
      const out = await service.checkScheduleConflictPreview(q);
      expect(out.hasConflict).toBe(false);
    });

    it('rejects preview when endAt is on a different Skopje calendar day', async () => {
      const q = Object.assign(new CheckEventConflictQueryDto(), {
        siteId: 'site-1',
        scheduledAt: '2025-07-01T20:00:00.000Z',
        endAt: '2025-07-01T22:30:00.000Z',
      });
      let thrown: unknown;
      try {
        await service.checkScheduleConflictPreview(q);
      } catch (e) {
        thrown = e;
      }
      expect(thrown).toBeInstanceOf(BadRequestException);
      expect((thrown as BadRequestException).getResponse()).toEqual(
        expect.objectContaining({ code: 'EVENTS_END_DIFFERENT_SKOPJE_CALENDAR_DAY' }),
      );
    });
  });

  describe('list', () => {
    it('throws on invalid status filter', async () => {
      const q = new ListEventsQueryDto();
      q.status = 'not-a-status';
      await expect(service.list(user('u1'), q)).rejects.toBeInstanceOf(BadRequestException);
    });

    it('throws on invalid category filter', async () => {
      const q = new ListEventsQueryDto();
      q.category = 'bogusCategory';
      await expect(service.list(user('u1'), q)).rejects.toBeInstanceOf(BadRequestException);
    });

    it('throws when one category in a comma list is invalid', async () => {
      const q = new ListEventsQueryDto();
      q.category = 'riverAndLake,bogusCategory';
      await expect(service.list(user('u1'), q)).rejects.toBeInstanceOf(BadRequestException);
    });

    it('applies OR semantics for multiple categories via Prisma in', async () => {
      prisma.cleanupEvent.findMany.mockResolvedValue([]);
      const q = new ListEventsQueryDto();
      q.category = 'riverAndLake,treeAndGreen,riverAndLake';
      await service.list(user('u1'), q);
      expect(prisma.cleanupEvent.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({
            AND: [
              expect.objectContaining({
                AND: expect.arrayContaining([
                  expect.objectContaining({
                    category: {
                      in: [EcoEventCategory.RIVER_AND_LAKE, EcoEventCategory.TREE_AND_GREEN],
                    },
                  }),
                ]),
              }),
              {},
            ],
          }),
        }),
      );
    });

    it('returns mapped events and pagination meta', async () => {
      prisma.cleanupEvent.findMany.mockResolvedValue([
        baseEvent({
          id: 'evt-a',
          scheduledAt: new Date('2025-08-01T09:00:00Z'),
        }),
      ]);
      const q = new ListEventsQueryDto();
      q.limit = 20;
      const out = await service.list(user('u1'), q);
      expect(out.data).toHaveLength(1);
      expect((out.data[0] as { id: string }).id).toBe('evt-a');
      expect(out.meta.hasMore).toBe(false);
      expect(out.meta.nextCursor).toBeNull();
      expect(prisma.cleanupEvent.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          take: 21,
          orderBy: [{ scheduledAt: 'desc' }, { id: 'desc' }],
        }),
      );
    });

  });

  describe('findOne', () => {
    it('throws when event not visible', async () => {
      prisma.cleanupEvent.findFirst.mockResolvedValue(null);
      await expect(service.findOne('missing', user('u1'))).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });

    it('returns mobile payload when found', async () => {
      prisma.cleanupEvent.findFirst.mockResolvedValue(baseEvent({ id: 'evt-1' }));
      const out = await service.findOne('evt-1', user('u1'));
      expect((out as { id: string }).id).toBe('evt-1');
    });

    it('does not query series metadata for standalone non-recurring events', async () => {
      prisma.cleanupEvent.findFirst.mockResolvedValue(
        baseEvent({ id: 'evt-1', recurrenceRule: null, parentEventId: null }),
      );
      await service.findOne('evt-1', user('u1'));
      expect(prisma.cleanupEvent.findMany).not.toHaveBeenCalled();
    });

    it('returns recurrence series navigation fields for recurring events', async () => {
      prisma.cleanupEvent.findFirst.mockResolvedValue(
        baseEvent({
          id: 'evt-child',
          parentEventId: 'evt-root',
          recurrenceRule: null,
          recurrenceIndex: 1,
          scheduledAt: new Date('2025-06-15T09:00:00Z'),
        }),
      );
      prisma.cleanupEvent.findMany.mockResolvedValue([
        { id: 'evt-root', scheduledAt: new Date('2025-06-01T09:00:00Z') },
        { id: 'evt-child', scheduledAt: new Date('2025-06-15T09:00:00Z') },
        { id: 'evt-child2', scheduledAt: new Date('2025-06-29T09:00:00Z') },
      ]);
      const out = (await service.findOne('evt-child', user('u1'))) as {
        recurrenceSeriesTotal: number | null;
        recurrenceSeriesPosition: number | null;
        recurrencePrevEventId: string | null;
        recurrenceNextEventId: string | null;
      };
      expect(out.recurrenceSeriesTotal).toBe(3);
      expect(out.recurrenceSeriesPosition).toBe(2);
      expect(out.recurrencePrevEventId).toBe('evt-root');
      expect(out.recurrenceNextEventId).toBe('evt-child2');
    });
  });

  describe('join', () => {
    it('rejects when caller is the organizer', async () => {
      prisma.cleanupEvent.findFirst.mockResolvedValue(
        baseEvent({ organizerId: 'u1', participants: [] }),
      );

      await expect(service.join('evt-1', user('u1'))).rejects.toBeInstanceOf(BadRequestException);
    });

    it('rejects when event is full', async () => {
      const future = new Date();
      future.setFullYear(future.getFullYear() + 1);
      prisma.cleanupEvent.findFirst.mockResolvedValue(
        baseEvent({
          organizerId: 'org-1',
          participantCount: 10,
          maxParticipants: 10,
          participants: [],
          scheduledAt: future,
        }),
      );

      await expect(service.join('evt-1', user('u2'))).rejects.toBeInstanceOf(ConflictException);
    });

    it('allows join before scheduledAt', async () => {
      const future = new Date();
      future.setFullYear(future.getFullYear() + 1);
      prisma.cleanupEvent.findFirst.mockResolvedValue(
        baseEvent({
          organizerId: 'org-1',
          participants: [],
          scheduledAt: future,
        }),
      );
      prisma.eventParticipant.create.mockResolvedValue({ id: 'part-new' });
      ecoEventPoints.creditIfNew.mockResolvedValue(5);
      prisma.cleanupEvent.findFirstOrThrow.mockResolvedValue(
        baseEvent({
          organizerId: 'org-1',
          participants: [{ id: 'part-new', reminderEnabled: false, reminderAt: null }],
          scheduledAt: future,
        }),
      );
      prisma.user.findUnique.mockResolvedValue({ firstName: 'Jane', lastName: 'Volunteer' });

      const out = await service.join('evt-1', user('u2'));

      expect((out as { pointsAwarded: number }).pointsAwarded).toBe(5);
    });

    it('rejects join after scheduledAt plus grace window', async () => {
      prisma.cleanupEvent.findFirst.mockResolvedValue(
        baseEvent({
          organizerId: 'org-1',
          participants: [],
          scheduledAt: new Date('2020-01-01T12:00:00.000Z'),
        }),
      );

      let thrown: unknown;
      try {
        await service.join('evt-1', user('u2'));
      } catch (e) {
        thrown = e;
      }
      expect(thrown).toBeInstanceOf(BadRequestException);
      expect((thrown as BadRequestException).getResponse()).toEqual(
        expect.objectContaining({ code: 'EVENT_JOIN_WINDOW_CLOSED' }),
      );
    });

    it('returns pointsAwarded when join succeeds', async () => {
      const future = new Date();
      future.setFullYear(future.getFullYear() + 1);
      prisma.cleanupEvent.findFirst.mockResolvedValue(
        baseEvent({
          organizerId: 'org-1',
          participants: [],
          scheduledAt: future,
        }),
      );
      prisma.eventParticipant.create.mockResolvedValue({ id: 'part-new' });
      ecoEventPoints.creditIfNew.mockResolvedValue(5);
      prisma.cleanupEvent.findFirstOrThrow.mockResolvedValue(
        baseEvent({
          organizerId: 'org-1',
          participants: [{ id: 'part-new', reminderEnabled: false, reminderAt: null }],
          scheduledAt: future,
        }),
      );
      prisma.user.findUnique.mockResolvedValue({ firstName: 'Jane', lastName: 'Volunteer' });

      const out = await service.join('evt-1', user('u2'));

      expect((out as { pointsAwarded: number }).pointsAwarded).toBe(5);
      expect(ecoEventPoints.creditIfNew).toHaveBeenCalledWith(
        prisma,
        expect.objectContaining({
          userId: 'u2',
          referenceType: 'CleanupEvent',
          referenceId: 'evt-1',
        }),
      );
    });
  });

  describe('patchLifecycle', () => {
    it('forbids non-organizer', async () => {
      prisma.cleanupEvent.findUnique.mockResolvedValue(
        baseEvent({ organizerId: 'org-1' }),
      );

      await expect(
        service.patchLifecycle('evt-1', { status: 'inProgress' }, user('u2')),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });

    it('rejects invalid transition from completed', async () => {
      prisma.cleanupEvent.findUnique.mockResolvedValue(
        baseEvent({
          organizerId: 'u1',
          lifecycleStatus: EcoEventLifecycleStatus.COMPLETED,
        }),
      );

      await expect(
        service.patchLifecycle('evt-1', { status: 'inProgress' }, user('u1')),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('rejects upcoming -> inProgress before scheduledAt', async () => {
      const future = new Date();
      future.setFullYear(future.getFullYear() + 1);
      prisma.cleanupEvent.findUnique.mockResolvedValue(
        baseEvent({
          organizerId: 'u1',
          lifecycleStatus: EcoEventLifecycleStatus.UPCOMING,
          scheduledAt: future,
        }),
      );
      prisma.cleanupEvent.update.mockClear();

      let thrown: unknown;
      try {
        await service.patchLifecycle('evt-1', { status: 'inProgress' }, user('u1'));
      } catch (e) {
        thrown = e;
      }
      expect(thrown).toBeInstanceOf(BadRequestException);
      expect((thrown as BadRequestException).getResponse()).toEqual(
        expect.objectContaining({ code: 'EVENT_START_TOO_EARLY' }),
      );
      expect(prisma.cleanupEvent.update).not.toHaveBeenCalled();
    });

    it('allows upcoming -> inProgress and sets completedAt on completed', async () => {
      prisma.cleanupEvent.findUnique.mockResolvedValue(
        baseEvent({
          organizerId: 'u1',
          lifecycleStatus: EcoEventLifecycleStatus.UPCOMING,
        }),
      );
      prisma.cleanupEvent.update.mockResolvedValue(
        baseEvent({
          organizerId: 'u1',
          lifecycleStatus: EcoEventLifecycleStatus.IN_PROGRESS,
        }),
      );

      await service.patchLifecycle('evt-1', { status: 'inProgress' }, user('u1'));

      expect(prisma.cleanupEvent.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            lifecycleStatus: EcoEventLifecycleStatus.IN_PROGRESS,
          }),
        }),
      );

      prisma.cleanupEvent.findUnique.mockResolvedValue(
        baseEvent({
          organizerId: 'u1',
          lifecycleStatus: EcoEventLifecycleStatus.IN_PROGRESS,
        }),
      );
      prisma.eventCheckIn.findMany.mockResolvedValue([{ userId: 'u2' }]);
      prisma.pointTransaction.findMany.mockResolvedValue([]);
      ecoEventPoints.creditIfNew.mockResolvedValue(30);
      prisma.cleanupEvent.update.mockResolvedValue(
        baseEvent({
          organizerId: 'u1',
          lifecycleStatus: EcoEventLifecycleStatus.COMPLETED,
          completedAt: new Date(),
          participants: [],
          checkIns: [],
        }),
      );

      await service.patchLifecycle('evt-1', { status: 'completed' }, user('u1'));

      expect(prisma.cleanupEvent.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            lifecycleStatus: EcoEventLifecycleStatus.COMPLETED,
            completedAt: expect.any(Date),
          }),
        }),
      );
      expect(ecoEventPoints.creditIfNew).toHaveBeenCalledWith(
        prisma,
        expect.objectContaining({
          userId: 'u2',
          referenceId: 'completion:evt-1:u2',
        }),
      );
      expect(notificationDispatcher.dispatchToUser).toHaveBeenCalledWith(
        'u2',
        expect.objectContaining({
          type: NotificationType.CLEANUP_EVENT,
          body: expect.stringContaining('30'),
        }),
      );
    });

    it('on completed, debits join bonus for users without check-in before completion awards', async () => {
      prisma.cleanupEvent.findUnique.mockResolvedValue(
        baseEvent({
          organizerId: 'u1',
          lifecycleStatus: EcoEventLifecycleStatus.IN_PROGRESS,
        }),
      );
      prisma.eventCheckIn.findMany.mockResolvedValue([{ userId: 'u2' }]);
      prisma.pointTransaction.findMany.mockResolvedValue([{ userId: 'u2' }, { userId: 'u3' }]);
      ecoEventPoints.debitOnceIfNew.mockImplementation(async (_tx, params: { userId: string }) => {
        return params.userId === 'u3' ? -5 : 0;
      });
      ecoEventPoints.creditIfNew.mockResolvedValue(30);
      prisma.cleanupEvent.update.mockResolvedValue(
        baseEvent({
          organizerId: 'u1',
          lifecycleStatus: EcoEventLifecycleStatus.COMPLETED,
          completedAt: new Date(),
          title: 'River cleanup',
        }),
      );

      await service.patchLifecycle('evt-1', { status: 'completed' }, user('u1'));

      expect(ecoEventPoints.debitOnceIfNew).toHaveBeenCalledWith(
        prisma,
        expect.objectContaining({
          userId: 'u3',
          delta: -5,
          referenceId: 'noShow:evt-1:u3',
        }),
      );
      expect(ecoEventPoints.creditIfNew).toHaveBeenCalledWith(
        prisma,
        expect.objectContaining({
          userId: 'u2',
          referenceId: 'completion:evt-1:u2',
        }),
      );
      expect(notificationDispatcher.dispatchToUser).toHaveBeenCalledWith(
        'u3',
        expect.objectContaining({
          body: expect.stringContaining('River cleanup'),
        }),
      );
    });

    it('on cancelled, does not query join grants or debit', async () => {
      prisma.cleanupEvent.findUnique.mockResolvedValue(
        baseEvent({
          organizerId: 'u1',
          lifecycleStatus: EcoEventLifecycleStatus.UPCOMING,
        }),
      );
      prisma.cleanupEvent.update.mockResolvedValue(
        baseEvent({
          organizerId: 'u1',
          lifecycleStatus: EcoEventLifecycleStatus.CANCELLED,
        }),
      );

      await service.patchLifecycle('evt-1', { status: 'cancelled' }, user('u1'));

      expect(prisma.$transaction).not.toHaveBeenCalled();
      expect(prisma.pointTransaction.findMany).not.toHaveBeenCalled();
      expect(ecoEventPoints.debitOnceIfNew).not.toHaveBeenCalled();
    });
  });

  describe('leave', () => {
    it('throws when event not found', async () => {
      prisma.cleanupEvent.findFirst.mockResolvedValue(null);
      await expect(service.leave('evt-1', user('u1'))).rejects.toBeInstanceOf(NotFoundException);
    });

    it('throws when user is not a participant', async () => {
      prisma.cleanupEvent.findFirst.mockResolvedValue({ id: 'evt-1' });
      prisma.eventParticipant.deleteMany.mockResolvedValue({ count: 0 });
      await expect(service.leave('evt-1', user('u1'))).rejects.toBeInstanceOf(BadRequestException);
    });

    it('decrements participant count and returns updated event', async () => {
      prisma.cleanupEvent.findFirst.mockResolvedValue({ id: 'evt-1' });
      prisma.eventParticipant.deleteMany.mockResolvedValue({ count: 1 });
      prisma.cleanupEvent.findFirstOrThrow.mockResolvedValue(
        baseEvent({ id: 'evt-1', participantCount: 1 }),
      );
      prisma.user.findUnique.mockResolvedValue({ firstName: 'Jane', lastName: 'Volunteer' });
      const out = await service.leave('evt-1', user('u1'));
      expect((out as { id: string }).id).toBe('evt-1');
      expect(prisma.cleanupEvent.update).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: 'evt-1' },
          data: { participantCount: { decrement: 1 } },
        }),
      );
      expect(ecoEventPoints.debitOnceIfNew).toHaveBeenCalledWith(
        prisma,
        expect.objectContaining({
          userId: 'u1',
          referenceId: 'leave:evt-1:u1',
        }),
      );
    });
  });

  describe('patchReminder', () => {
    it('requires join before setting reminder', async () => {
      prisma.cleanupEvent.findFirst.mockResolvedValue({ id: 'evt-1' });
      prisma.eventParticipant.findUnique.mockResolvedValue(null);
      const dto = new PatchEventReminderDto();
      dto.reminderEnabled = true;
      dto.reminderAt = '2025-07-01T08:00:00.000Z';
      await expect(service.patchReminder('evt-1', dto, user('u1'))).rejects.toBeInstanceOf(
        ForbiddenException,
      );
    });

    it('updates reminder and returns event', async () => {
      prisma.cleanupEvent.findFirst.mockResolvedValue({ id: 'evt-1' });
      prisma.eventParticipant.findUnique.mockResolvedValue({
        id: 'p1',
        reminderEnabled: false,
        reminderAt: null,
      });
      prisma.eventParticipant.update.mockResolvedValue({});
      prisma.cleanupEvent.findFirstOrThrow.mockResolvedValue(baseEvent({ id: 'evt-1' }));
      const dto = new PatchEventReminderDto();
      dto.reminderEnabled = true;
      dto.reminderAt = '2025-07-01T08:00:00.000Z';
      const out = await service.patchReminder('evt-1', dto, user('u1'));
      expect((out as { id: string }).id).toBe('evt-1');
      expect(prisma.eventParticipant.update).toHaveBeenCalled();
    });
  });

  describe('appendAfterImages', () => {
    it('forbids non-organizer uploads', async () => {
      prisma.cleanupEvent.findUnique.mockResolvedValue(
        baseEvent({ organizerId: 'org-1', afterImageKeys: [] }),
      );
      await expect(
        service.appendAfterImages(
          'evt-1',
          [{ buffer: Buffer.from('x'), mimetype: 'image/jpeg', size: 1, originalname: 'a.jpg' }] as never,
          user('u2'),
        ),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });

    it('merges new image keys for organizer', async () => {
      prisma.cleanupEvent.findUnique.mockResolvedValue(
        baseEvent({
          id: 'evt-1',
          organizerId: 'org-1',
          afterImageKeys: ['old/key.webp'],
        }),
      );
      cleanupMediaUpload.uploadCleanupEventAfterImages.mockResolvedValue(['new/key.webp']);
      prisma.cleanupEvent.update.mockResolvedValue(
        baseEvent({
          id: 'evt-1',
          organizerId: 'org-1',
          afterImageKeys: ['old/key.webp', 'new/key.webp'],
        }),
      );
      const out = await service.appendAfterImages(
        'evt-1',
        [{ buffer: Buffer.from('x'), mimetype: 'image/jpeg', size: 1, originalname: 'a.jpg' }] as never,
        user('org-1'),
      );
      expect(cleanupMediaUpload.uploadCleanupEventAfterImages).toHaveBeenCalled();
      expect(prisma.cleanupEvent.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: { afterImageKeys: ['old/key.webp', 'new/key.webp'] },
        }),
      );
      expect((out as { id: string }).id).toBe('evt-1');
    });
  });

  describe('getAnalytics', () => {
    it('returns 403 for non-organizer non-staff', async () => {
      prisma.cleanupEvent.findUnique.mockResolvedValue({
        organizerId: 'org-1',
        participantCount: 5,
      });
      prisma.eventParticipant.findMany.mockResolvedValue([]);
      prisma.eventCheckIn.findMany.mockResolvedValue([]);
      await expect(service.getAnalytics('evt-1', user('u2'))).rejects.toBeInstanceOf(ForbiddenException);
    });

    it('returns analytics for organizer', async () => {
      prisma.cleanupEvent.findUnique.mockResolvedValue({
        organizerId: 'org-1',
        participantCount: 2,
      });
      prisma.eventParticipant.findMany.mockResolvedValue([
        { joinedAt: new Date('2025-06-01T10:00:00Z') },
        { joinedAt: new Date('2025-06-01T14:00:00Z') },
      ]);
      prisma.eventCheckIn.count.mockResolvedValue(1);
      prisma.eventCheckIn.findMany.mockResolvedValue([
        { checkedInAt: new Date('2025-06-01T11:15:00Z') },
      ]);
      prisma.$queryRaw.mockResolvedValue([{ hour: 11, count: BigInt(1) }]);
      const out = await service.getAnalytics('evt-1', user('org-1'));
      expect(out.totalJoiners).toBe(2);
      expect(out.checkedInCount).toBe(1);
      expect(out.attendanceRate).toBe(50);
      expect(out.joinersCumulative).toHaveLength(2);
      expect(out.joinersCumulative[0].cumulativeJoiners).toBe(1);
      expect(out.joinersCumulative[1].cumulativeJoiners).toBe(2);
      expect(out.checkInsByHour).toHaveLength(24);
      expect(out.checkInsByHour[11].count).toBe(1);
    });
  });

  describe('patchEvent', () => {
    it('forbids non-organizer updates', async () => {
      prisma.cleanupEvent.findUnique.mockResolvedValue(baseEvent({ organizerId: 'org-1' }));

      await expect(
        service.patchEvent('evt-1', { title: 'Hijacked' }, user('u2')),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });

    it('passes excludeEventId to schedule conflict when changing scheduledAt', async () => {
      prisma.cleanupEvent.findUnique.mockResolvedValue(
        baseEvent({ id: 'evt-1', organizerId: 'org-1', siteId: 'site-1' }),
      );
      prisma.cleanupEvent.update.mockResolvedValue(
        baseEvent({
          id: 'evt-1',
          organizerId: 'org-1',
          siteId: 'site-1',
          scheduledAt: new Date('2025-08-01T10:00:00.000Z'),
        }),
      );
      scheduleConflict.findConflictingEvent.mockResolvedValue(null);
      await service.patchEvent(
        'evt-1',
        { scheduledAt: '2025-08-01T10:00:00.000Z' },
        user('org-1'),
      );
      expect(scheduleConflict.findConflictingEvent).toHaveBeenCalledWith(
        expect.objectContaining({
          siteId: 'site-1',
          excludeEventId: 'evt-1',
        }),
      );
    });

    it('throws ConflictException when new schedule conflicts with another event', async () => {
      prisma.cleanupEvent.findUnique.mockResolvedValue(
        baseEvent({ id: 'evt-1', organizerId: 'org-1', siteId: 'site-1' }),
      );
      scheduleConflict.findConflictingEvent.mockResolvedValue({
        id: 'other',
        title: 'Other',
        scheduledAt: new Date('2025-08-01T12:00:00.000Z'),
      });
      await expect(
        service.patchEvent(
          'evt-1',
          { scheduledAt: '2025-08-01T10:00:00.000Z' },
          user('org-1'),
        ),
      ).rejects.toBeInstanceOf(ConflictException);
      expect(prisma.cleanupEvent.update).not.toHaveBeenCalled();
    });

    it('rejects PATCH when lifecycle is completed', async () => {
      prisma.cleanupEvent.findUnique.mockResolvedValue(
        baseEvent({
          organizerId: 'org-1',
          lifecycleStatus: EcoEventLifecycleStatus.COMPLETED,
        }),
      );

      let thrown: unknown;
      try {
        await service.patchEvent('evt-1', { title: 'New title' }, user('org-1'));
      } catch (e) {
        thrown = e;
      }
      expect(thrown).toBeInstanceOf(BadRequestException);
      expect((thrown as BadRequestException).getResponse()).toEqual(
        expect.objectContaining({ code: 'EVENT_NOT_EDITABLE' }),
      );
      expect(prisma.cleanupEvent.update).not.toHaveBeenCalled();
    });

    it('returns an approved event to PENDING when organizer changes title', async () => {
      prisma.cleanupEvent.findUnique.mockResolvedValue(
        baseEvent({ organizerId: 'org-1', status: CleanupEventStatus.APPROVED }),
      );
      prisma.cleanupEvent.update.mockResolvedValue(
        baseEvent({
          organizerId: 'org-1',
          status: CleanupEventStatus.PENDING,
          title: 'New title',
        }),
      );
      scheduleConflict.findConflictingEvent.mockResolvedValue(null);
      await service.patchEvent('evt-1', { title: 'New title' }, user('org-1'));
      expect(prisma.cleanupEvent.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({ status: CleanupEventStatus.PENDING }),
        }),
      );
      expect(cleanupEventsSse.emitCleanupEventPending).toHaveBeenCalledWith('evt-1');
      expect(cleanupEventNotifications.notifyStaffPendingReview).toHaveBeenCalled();
    });
  });

  describe('listParticipants', () => {
    it('throws when event is not visible', async () => {
      prisma.cleanupEvent.findFirst.mockResolvedValue(null);

      await expect(
        service.listParticipants('evt-missing', user('u1'), new ListEventParticipantsQueryDto()),
      ).rejects.toBeInstanceOf(NotFoundException);
      expect(prisma.eventParticipant.findMany).not.toHaveBeenCalled();
    });

    it('rejects invalid participants cursor', async () => {
      prisma.cleanupEvent.findFirst.mockResolvedValue({ id: 'evt-1' });
      const q = new ListEventParticipantsQueryDto();
      q.cursor = 'not-a-valid-cursor';

      await expect(service.listParticipants('evt-1', user('viewer'), q)).rejects.toBeInstanceOf(
        BadRequestException,
      );
    });

    it('returns joiners ordered with pagination meta', async () => {
      prisma.cleanupEvent.findFirst.mockResolvedValue({ id: 'evt-1' });
      const j1 = new Date('2025-06-01T10:00:00.000Z');
      const j2 = new Date('2025-06-01T11:00:00.000Z');
      prisma.eventParticipant.findMany.mockResolvedValue([
        {
          id: 'p1',
          joinedAt: j1,
          userId: 'u1',
          user: { firstName: 'Ana', lastName: 'Miteva', avatarObjectKey: null as string | null },
        },
        {
          id: 'p2',
          joinedAt: j2,
          userId: 'u2',
          user: { firstName: 'Marko', lastName: 'Todorov', avatarObjectKey: null as string | null },
        },
      ]);

      const q = new ListEventParticipantsQueryDto();
      q.limit = 1;
      const result = await service.listParticipants('evt-1', user('viewer'), q);

      expect(result.data).toHaveLength(1);
      expect(result.data[0]).toEqual({
        userId: 'u1',
        displayName: 'Ana Miteva',
        avatarUrl: null,
        joinedAt: j1.toISOString(),
      });
      expect(result.meta.hasMore).toBe(true);
      expect(result.meta.nextCursor).toEqual(expect.any(String));
    });
  });
});
