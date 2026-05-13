/// <reference types="jest" />

import { firstValueFrom, of } from 'rxjs';
import { take } from 'rxjs/operators';
import type { AuthenticatedUser } from '../../src/auth/types/authenticated-user.type';
import { Role } from '../../src/prisma-client';
import { EventsLiveImpactController } from '../../src/events/events-live-impact.controller';
import { EventLiveImpactService } from '../../src/events/event-live-impact.service';
import { EventsQueryService } from '../../src/events/events-query.service';

function user(id: string): AuthenticatedUser {
  return {
    userId: id,
    email: `${id}@test.chisto.mk`,
    phoneNumber: '+38970000000',
    role: Role.USER,
  };
}

describe('EventsLiveImpactController', () => {
  const getSnapshot = jest.fn();
  const watchLiveImpactSse = jest.fn();
  const patch = jest.fn();
  const findOne = jest.fn();

  let controller: EventsLiveImpactController;

  beforeEach(() => {
    getSnapshot.mockReset();
    watchLiveImpactSse.mockReset();
    patch.mockReset();
    findOne.mockReset();
    controller = new EventsLiveImpactController(
      {
        getSnapshot,
        watchLiveImpactSse,
        patch,
      } as unknown as EventLiveImpactService,
      { findOne } as unknown as EventsQueryService,
    );
  });

  it('getLiveImpact forwards id and user', async () => {
    const u = user('u1');
    const id = 'c012345678901234567890123';
    const snap = { checkedInCount: 3 };
    getSnapshot.mockResolvedValue(snap);

    const result = await controller.getLiveImpact(u, id);

    expect(getSnapshot).toHaveBeenCalledWith(id, u);
    expect(result).toBe(snap);
  });

  it('streamLiveImpact wires watchLiveImpactSse and emits merged events', async () => {
    const u = user('u1');
    const id = 'c012345678901234567890123';
    watchLiveImpactSse.mockReturnValue(of({ data: { type: 'tick' } }));

    const stream$ = controller.streamLiveImpact(u, id);
    const first = await firstValueFrom(stream$.pipe(take(1)));

    expect(watchLiveImpactSse).toHaveBeenCalledWith(id, u);
    expect(first).toEqual(expect.objectContaining({ data: expect.anything() }));
  });

  it('patchLiveImpact patches then returns findOne', async () => {
    const u = user('u1');
    const id = 'c012345678901234567890123';
    const dto = { bagsCollected: 12 } as never;
    const updated = { id, title: 'T' };
    patch.mockResolvedValue(undefined);
    findOne.mockResolvedValue(updated);

    const result = await controller.patchLiveImpact(u, id, dto);

    expect(patch).toHaveBeenCalledWith(id, dto, u);
    expect(findOne).toHaveBeenCalledWith(id, u);
    expect(result).toBe(updated);
  });
});
