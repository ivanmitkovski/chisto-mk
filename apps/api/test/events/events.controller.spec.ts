/// <reference types="jest" />

import { BadRequestException, NotFoundException } from '@nestjs/common';
import { ParseCuidPipe } from '../../src/common/pipes/parse-cuid.pipe';
import type { AuthenticatedUser } from '../../src/auth/types/authenticated-user.type';
import { Role } from '../../src/prisma-client';
import { FindEventQueryDto } from '../../src/events/dto/find-event-query.dto';
import { ListEventsQueryDto } from '../../src/events/dto/list-events-query.dto';
import { EventsCheckInController } from '../../src/events/events-check-in.controller';
import { EventsCheckInService } from '../../src/events/events-check-in.service';
import { EventsController } from '../../src/events/events.controller';
import { EventsListController } from '../../src/events/events-list.controller';

function user(id: string): AuthenticatedUser {
  return {
    userId: id,
    email: `${id}@test.chisto.mk`,
    phoneNumber: '+38970000000',
    role: Role.USER,
  };
}

describe('EventsController', () => {
  let listController: EventsListController;
  let controller: EventsController;
  const list = jest.fn();
  const findOne = jest.fn();
  const findPublicShareCard = jest.fn();
  const create = jest.fn();
  const join = jest.fn();
  const search = jest.fn();
  const checkScheduleConflictPreview = jest.fn();
  const getAnalytics = jest.fn();

  beforeEach(() => {
    list.mockReset();
    findOne.mockReset();
    findPublicShareCard.mockReset();
    create.mockReset();
    join.mockReset();
    search.mockReset();
    checkScheduleConflictPreview.mockReset();
    getAnalytics.mockReset();

    const querySvc = { list, findOne, listParticipants: jest.fn() };
    const creationSvc = { create };
    const eventSearchSvc = { search };
    const schedulePreviewSvc = { checkScheduleConflictPreview };
    const updatesSvc = { patchEvent: jest.fn() };
    const lifecycleSvc = { patchLifecycle: jest.fn() };
    const participationSvc = { join, leave: jest.fn(), patchReminder: jest.fn() };
    const afterImagesSvc = { appendAfterImages: jest.fn() };
    const analyticsSvc = { getAnalytics };
    const shareCardSvc = { findPublicShareCard };

    listController = new EventsListController(
      querySvc as never,
      creationSvc as never,
      eventSearchSvc as never,
      schedulePreviewSvc as never,
      { applyBatch: jest.fn() } as never,
    );
    controller = new EventsController(
      querySvc as never,
      updatesSvc as never,
      lifecycleSvc as never,
      participationSvc as never,
      afterImagesSvc as never,
      analyticsSvc as never,
      shareCardSvc as never,
      { buildForViewer: jest.fn() } as never,
    );
  });

  it('list forwards user and query to EventsQueryService', async () => {
    const u = user('u1');
    const query = Object.assign(new ListEventsQueryDto(), { limit: 10 });
    const payload = { data: [], meta: { hasMore: false, nextCursor: null } };
    list.mockResolvedValue(payload);

    const result = await listController.list(u, query);

    expect(list).toHaveBeenCalledWith(u, query);
    expect(result).toBe(payload);
  });

  it('findOne forwards id, user, and optional geo query', async () => {
    const u = user('u1');
    const event = { id: 'evt-1', title: 'River' };
    findOne.mockResolvedValue(event);
    const geo = new FindEventQueryDto();

    const result = await controller.findOne(u, 'evt-1', geo);

    expect(findOne).toHaveBeenCalledWith('evt-1', u, geo);
    expect(result).toBe(event);
  });

  it('getPublicShareCard path validation rejects blank ids (ParseCuidPipe)', () => {
    const pipe = new ParseCuidPipe();
    expect(() => pipe.transform('   ')).toThrow(BadRequestException);
  });

  it('getPublicShareCard forwards cuid-shaped id to EventsShareCardQueryService', async () => {
    const cuid = 'c012345678901234567890123';
    const card = {
      id: cuid,
      title: 'River',
      siteLabel: 'Skopje',
      scheduledAt: '2026-06-01T08:00:00.000Z',
      endAt: null,
      lifecycleStatus: 'UPCOMING',
    };
    findPublicShareCard.mockResolvedValue(card);

    const result = await controller.getPublicShareCard(cuid);

    expect(findPublicShareCard).toHaveBeenCalledWith(cuid);
    expect(result).toBe(card);
  });

  it('getPublicShareCard forwards arbitrary id to share card service (not found from service)', async () => {
    findPublicShareCard.mockRejectedValue(
      new NotFoundException({ code: 'EVENT_NOT_FOUND', message: 'Event not found' }),
    );
    await expect(controller.getPublicShareCard('not-a-cuid')).rejects.toBeInstanceOf(NotFoundException);
    expect(findPublicShareCard).toHaveBeenCalledWith('not-a-cuid');
  });

  it('getPublicShareCard forwards trimmed cuid to share card service', async () => {
    const id = 'c012345678901234567890123';
    const card = { id, title: 'River', siteLabel: 'Skopje', scheduledAt: '2026-06-01T08:00:00.000Z', endAt: null, lifecycleStatus: 'UPCOMING' };
    findPublicShareCard.mockResolvedValue(card);

    const trimmed = new ParseCuidPipe().transform(`  ${id}  `);
    const result = await controller.getPublicShareCard(trimmed);

    expect(findPublicShareCard).toHaveBeenCalledWith(id);
    expect(result).toBe(card);
  });

  it('getImpactReceipt forwards id and user to EventImpactReceiptService', async () => {
    const u = user('u1');
    const receipt = { eventId: 'evt-1', title: 'River' };
    const buildForViewer = jest.fn().mockResolvedValue(receipt);
    const querySvc = {
      list: jest.fn(),
      findOne: jest.fn(),
      listParticipants: jest.fn(),
    };
    const ctrl = new EventsController(
      querySvc as never,
      { patchEvent: jest.fn() } as never,
      { patchLifecycle: jest.fn() } as never,
      { join: jest.fn(), leave: jest.fn(), patchReminder: jest.fn() } as never,
      { appendAfterImages: jest.fn() } as never,
      { getAnalytics: jest.fn() } as never,
      { findPublicShareCard: jest.fn() } as never,
      { buildForViewer } as never,
    );

    const result = await ctrl.getImpactReceipt(u, 'evt-1');

    expect(buildForViewer).toHaveBeenCalledWith('evt-1', u);
    expect(result).toBe(receipt);
  });

  it('create forwards dto and user', async () => {
    const u = user('u1');
    const dto = {
      siteId: 's1',
      title: 'Cleanup',
      description: 'Desc',
      category: 'riverAndLake',
      scheduledAt: '2026-06-01T08:00:00.000Z',
      endAt: '2026-06-01T10:00:00.000Z',
      gear: ['trashBags'],
    };
    const created = { id: 'new', title: 'Cleanup' };
    create.mockResolvedValue(created);

    const result = await listController.create(u, dto as never);

    expect(create).toHaveBeenCalledWith(dto, u);
    expect(result).toBe(created);
  });

  it('join forwards id and user', async () => {
    const u = user('u1');
    const updated = { id: 'evt-1', isJoined: true };
    join.mockResolvedValue(updated);

    const result = await controller.join(u, 'evt-1');

    expect(join).toHaveBeenCalledWith('evt-1', u);
    expect(result).toBe(updated);
  });
});

describe('EventsCheckInController', () => {
  it('rotateSession delegates to EventsCheckInService', async () => {
    const rotateSession = jest.fn().mockResolvedValue(undefined);
    const checkController = new EventsCheckInController({
      patchOpen: jest.fn(),
      rotateSession,
      getQrPayload: jest.fn(),
      listAttendees: jest.fn(),
      manualAdd: jest.fn(),
      removeAttendee: jest.fn(),
      redeem: jest.fn(),
    } as unknown as EventsCheckInService);

    const u = user('org-1');
    await checkController.rotateSession('evt-1', u);

    expect(rotateSession).toHaveBeenCalledWith('evt-1', u);
  });
});
