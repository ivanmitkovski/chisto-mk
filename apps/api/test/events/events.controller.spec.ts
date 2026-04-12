/// <reference types="jest" />

import type { AuthenticatedUser } from '../../src/auth/types/authenticated-user.type';
import { Role } from '../../src/prisma-client';
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
  const create = jest.fn();
  const join = jest.fn();

  beforeEach(() => {
    list.mockReset();
    findOne.mockReset();
    create.mockReset();
    join.mockReset();

    controller = new EventsController({
      list,
      findOne,
      create,
      patchEvent: jest.fn(),
      join,
      leave: jest.fn(),
      patchLifecycle: jest.fn(),
      patchReminder: jest.fn(),
      appendAfterImages: jest.fn(),
      listParticipants: jest.fn(),
    } as unknown as EventsService);
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

  it('findOne forwards id and user', async () => {
    const u = user('u1');
    const event = { id: 'evt-1', title: 'River' };
    findOne.mockResolvedValue(event);

    const result = await controller.findOne(u, 'evt-1');

    expect(findOne).toHaveBeenCalledWith('evt-1', u);
    expect(result).toBe(event);
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
