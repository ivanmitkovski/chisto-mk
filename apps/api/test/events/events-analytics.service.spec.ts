/// <reference types="jest" />

import { ForbiddenException, NotFoundException } from '@nestjs/common';
import type { AuthenticatedUser } from '../../src/auth/types/authenticated-user.type';
import { EventsAnalyticsService } from '../../src/events/events-analytics.service';
import { EventsRepository } from '../../src/events/events.repository';

function auth(userId: string, role: string = 'USER'): AuthenticatedUser {
  return {
    userId,
    email: `${userId}@test.chisto.mk`,
    phoneNumber: '+38970000000',
    role: role as never,
  };
}

describe('EventsAnalyticsService', () => {
  let service: EventsAnalyticsService;
  let findUnique: jest.Mock;
  let findMany: jest.Mock;
  let count: jest.Mock;
  let queryRaw: jest.Mock;

  beforeEach(() => {
    findUnique = jest.fn();
    findMany = jest.fn();
    count = jest.fn();
    queryRaw = jest.fn();
    const prisma = {
      cleanupEvent: { findUnique },
      eventParticipant: { findMany },
      eventCheckIn: { count },
      $queryRaw: queryRaw,
    };
    const repo = { prisma } as unknown as EventsRepository;
    service = new EventsAnalyticsService(repo);
  });

  it('throws NotFoundException when event missing', async () => {
    findUnique.mockResolvedValue(null);
    await expect(service.getAnalytics('x', auth('u1'))).rejects.toBeInstanceOf(NotFoundException);
  });

  it('throws ForbiddenException for non-organizer non-staff', async () => {
    findUnique.mockResolvedValue({ organizerId: 'org-1', participantCount: 0 });
    await expect(service.getAnalytics('e1', auth('other'))).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('returns payload for organizer', async () => {
    findUnique.mockResolvedValue({ organizerId: 'org-1', participantCount: 1 });
    findMany.mockResolvedValue([{ joinedAt: new Date('2025-01-01T12:00:00Z') }]);
    count.mockResolvedValue(0);
    queryRaw.mockResolvedValue([]);
    const out = await service.getAnalytics('e1', auth('org-1'));
    expect(out.totalJoiners).toBe(1);
    expect(out.checkInsByHour).toHaveLength(24);
  });
});
