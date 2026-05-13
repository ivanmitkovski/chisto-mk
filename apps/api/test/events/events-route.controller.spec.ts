/// <reference types="jest" />

import type { AuthenticatedUser } from '../../src/auth/types/authenticated-user.type';
import { Role } from '../../src/prisma-client';
import { EventsRouteController } from '../../src/events/events-route.controller';
import { EventRouteSegmentsService } from '../../src/events/event-route-segments.service';

function user(id: string): AuthenticatedUser {
  return {
    userId: id,
    email: `${id}@test.chisto.mk`,
    phoneNumber: '+38970000000',
    role: Role.USER,
  };
}

describe('EventsRouteController', () => {
  const listForEvent = jest.fn();
  const replaceWaypoints = jest.fn();
  const claimSegment = jest.fn();
  const completeSegment = jest.fn();

  let controller: EventsRouteController;

  beforeEach(() => {
    listForEvent.mockReset();
    replaceWaypoints.mockReset();
    claimSegment.mockReset();
    completeSegment.mockReset();
    controller = new EventsRouteController({
      listForEvent,
      replaceWaypoints,
      claimSegment,
      completeSegment,
    } as unknown as EventRouteSegmentsService);
  });

  it('listRoute forwards event id and user', async () => {
    const u = user('u1');
    const id = 'c012345678901234567890123';
    const rows = [{ id: 'seg-1' }];
    listForEvent.mockResolvedValue(rows);

    const result = await controller.listRoute(u, id);

    expect(listForEvent).toHaveBeenCalledWith(id, u);
    expect(result).toBe(rows);
  });

  it('patchRoute forwards id, user, and waypoints', async () => {
    const u = user('u1');
    const id = 'c012345678901234567890123';
    const waypoints = [{ lat: 41.99, lng: 21.42, label: 'A' }];
    replaceWaypoints.mockResolvedValue(waypoints);

    const result = await controller.patchRoute(u, id, { waypoints } as never);

    expect(replaceWaypoints).toHaveBeenCalledWith(id, u, waypoints);
    expect(result).toBe(waypoints);
  });

  it('claimRouteSegment forwards segment id and user', async () => {
    const u = user('u1');
    const segmentId = 'c012345678901234567890124';
    claimSegment.mockResolvedValue([]);

    await controller.claimRouteSegment(u, 'c012345678901234567890123', segmentId);

    expect(claimSegment).toHaveBeenCalledWith(segmentId, u);
  });

  it('completeRouteSegment forwards segment id and user', async () => {
    const u = user('u1');
    const segmentId = 'c012345678901234567890125';
    completeSegment.mockResolvedValue([]);

    await controller.completeRouteSegment(u, 'c012345678901234567890123', segmentId);

    expect(completeSegment).toHaveBeenCalledWith(segmentId, u);
  });
});
