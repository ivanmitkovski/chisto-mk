/// <reference types="jest" />

import { NotFoundException } from '@nestjs/common';
import { Role } from '../../src/prisma-client';
import type { AuthenticatedUser } from '../../src/auth/types/authenticated-user.type';
import { EventRouteSegmentsService } from '../../src/events/event-route-segments.service';
import { PrismaService } from '../../src/prisma/prisma.service';

function user(): AuthenticatedUser {
  return {
    userId: 'u1',
    email: 'u1@test.chisto.mk',
    phoneNumber: '+38970000000',
    role: Role.USER,
  };
}

describe('EventRouteSegmentsService', () => {
  it('listForEvent throws when event not visible', async () => {
    const prisma = {
      cleanupEvent: { findFirst: jest.fn().mockResolvedValue(null) },
      eventRouteSegment: { findMany: jest.fn() },
    } as unknown as PrismaService;
    const svc = new EventRouteSegmentsService(prisma);

    await expect(svc.listForEvent('evt-1', user())).rejects.toBeInstanceOf(NotFoundException);
  });
});
