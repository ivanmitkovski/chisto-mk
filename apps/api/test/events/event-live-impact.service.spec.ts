/// <reference types="jest" />

import { NotFoundException } from '@nestjs/common';
import { Role } from '../../src/prisma-client';
import type { AuthenticatedUser } from '../../src/auth/types/authenticated-user.type';
import { EventCheckInRoomEmitterService } from '../../src/events/event-check-in-room-emitter.service';
import { EventLiveImpactEventsService } from '../../src/events/event-live-impact-events.service';
import { EventLiveImpactService } from '../../src/events/event-live-impact.service';
import { PrismaService } from '../../src/prisma/prisma.service';

function user(): AuthenticatedUser {
  return {
    userId: 'u1',
    email: 'u1@test.chisto.mk',
    phoneNumber: '+38970000000',
    role: Role.USER,
  };
}

describe('EventLiveImpactService', () => {
  it('getSnapshot throws when event missing', async () => {
    const prisma = {
      cleanupEvent: { findFirst: jest.fn().mockResolvedValue(null) },
    } as unknown as PrismaService;
    const bus = {} as unknown as EventLiveImpactEventsService;
    const roomEmitter = { emitToRoom: jest.fn() } as unknown as EventCheckInRoomEmitterService;
    const svc = new EventLiveImpactService(prisma, bus, roomEmitter);

    await expect(svc.getSnapshot('evt-1', user())).rejects.toBeInstanceOf(NotFoundException);
  });
});
