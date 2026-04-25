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
import { EventsService } from '../../src/events/events.service';

function user(id: string): AuthenticatedUser {
  return {
    userId: id,
    email: `${id}@test.chisto.mk`,
    phoneNumber: '+38970000000',
    role: Role.USER,
  };
}

describe('EventsController', () => {
  let controller: EventsController;
  const list = jest.fn();
  const findOne = jest.fn();
  const findPublicShareCard = jest.fn();
  const create = jest.fn();
  const join = jest.fn();

  beforeEach(() => {
    list.mockReset();
    findOne.mockReset();
    findPublicShareCard.mockReset();
    create.mockReset();
    join.mockReset();

    controller = new EventsController(
      {
        list,
        findOne,
        findPublicShareCard,
        create,
        patchEvent: jest.fn(),
        join,
        leave: jest.fn(),
        patchLifecycle: jest.fn(),
        patchReminder: jest.fn(),
        appendAfterImages: jest.fn(),
        listParticipants: jest.fn(),
      } as unknown as EventsService,
      { getSnapshot: jest.fn(), watchLiveImpactSse: jest.fn(), patch: jest.fn() } as never,
      { listForEvent: jest.fn(), addPhoto: jest.fn(), deletePhoto: jest.fn() } as never,
      {
        listForEvent: jest.fn(),
        replaceWaypoints: jest.fn(),
        claimSegment: jest.fn(),
        completeSegment: jest.fn(),
      } as never,
      { applyBatch: jest.fn() } as never,
      { buildForViewer: jest.fn() } as never,
    );
  });

  it('list forwards user and query to EventsService', async () => {
    const u = user('u1');
    const query = Object.assign(new ListEventsQueryDto(), { limit: 10 });
    const payload = { data: [], meta: { hasMore: false, nextCursor: null } };
    list.mockResolvedValue(payload);

    const result = await controller.list(u, query);

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

  it('getPublicShareCard forwards cuid-shaped id to EventsService', async () => {
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

  it('getPublicShareCard forwards arbitrary id to EventsService (not found from service)', async () => {
    findPublicShareCard.mockRejectedValue(
      new NotFoundException({ code: 'EVENT_NOT_FOUND', message: 'Event not found' }),
    );
    await expect(controller.getPublicShareCard('not-a-cuid')).rejects.toBeInstanceOf(NotFoundException);
    expect(findPublicShareCard).toHaveBeenCalledWith('not-a-cuid');
  });

  it('getPublicShareCard forwards trimmed cuid to EventsService', async () => {
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
    const ctrl = new EventsController(
      {
        list,
        findOne,
        findPublicShareCard: jest.fn(),
        create: jest.fn(),
        patchEvent: jest.fn(),
        join: jest.fn(),
        leave: jest.fn(),
        patchLifecycle: jest.fn(),
        patchReminder: jest.fn(),
        appendAfterImages: jest.fn(),
        listParticipants: jest.fn(),
      } as unknown as EventsService,
      { getSnapshot: jest.fn(), watchLiveImpactSse: jest.fn(), patch: jest.fn() } as never,
      { listForEvent: jest.fn(), addPhoto: jest.fn(), deletePhoto: jest.fn() } as never,
      {
        listForEvent: jest.fn(),
        replaceWaypoints: jest.fn(),
        claimSegment: jest.fn(),
        completeSegment: jest.fn(),
      } as never,
      { applyBatch: jest.fn() } as never,
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

    const result = await controller.create(u, dto as never);

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
