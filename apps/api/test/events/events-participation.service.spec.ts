/// <reference types="jest" />

import { NotFoundException } from '@nestjs/common';
import type { AuthenticatedUser } from '../../src/auth/types/authenticated-user.type';
import { EventsParticipationService } from '../../src/events/events-participation.service';
import { EventsMobileMapperService } from '../../src/events/events-mobile-mapper.service';
import { EventsRepository } from '../../src/events/events.repository';

function auth(userId: string): AuthenticatedUser {
  return {
    userId,
    email: `${userId}@test.chisto.mk`,
    phoneNumber: '+38970000000',
    role: 'USER' as never,
  };
}

describe('EventsParticipationService', () => {
  let service: EventsParticipationService;
  let findFirst: jest.Mock;

  beforeEach(() => {
    findFirst = jest.fn();
    const prisma = { cleanupEvent: { findFirst } };
    const repo = { prisma } as unknown as EventsRepository;
    const mobileMapper = {} as EventsMobileMapperService;
    service = new EventsParticipationService(
      repo,
      mobileMapper,
      {} as never,
      {} as never,
      {} as never,
    );
  });

  it('join throws NotFoundException when event is not visible', async () => {
    findFirst.mockResolvedValue(null);
    await expect(service.join('evt-x', auth('u1'))).rejects.toBeInstanceOf(NotFoundException);
  });
});
