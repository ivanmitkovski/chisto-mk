/// <reference types="jest" />

import { ForbiddenException, NotFoundException } from '@nestjs/common';
import {
  CleanupEventStatus,
  EcoEventLifecycleStatus,
} from '../../src/prisma-client';
import type { AuthenticatedUser } from '../../src/auth/types/authenticated-user.type';
import { PatchEventLifecycleDto } from '../../src/events/dto/patch-event-lifecycle.dto';
import { EventsLifecycleService } from '../../src/events/events-lifecycle.service';
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

describe('EventsLifecycleService', () => {
  let service: EventsLifecycleService;
  let findUnique: jest.Mock;
  let update: jest.Mock;

  beforeEach(() => {
    findUnique = jest.fn();
    update = jest.fn();
    const prisma = { cleanupEvent: { findUnique, update } };
    const repo = { prisma } as unknown as EventsRepository;
    const mobileMapper = {
      toMobileEvent: jest.fn((e: unknown) => ({ mapped: true, e })),
    } as unknown as EventsMobileMapperService;
    const ecoEventPoints = {
      awardPoints: jest.fn(),
      clawBackPoints: jest.fn(),
    };
    const notificationDispatcher = { dispatch: jest.fn() };
    service = new EventsLifecycleService(
      repo,
      mobileMapper,
      ecoEventPoints as never,
      notificationDispatcher as never,
    );
  });

  it('throws NotFoundException when event is missing', async () => {
    findUnique.mockResolvedValue(null);
    await expect(
      service.patchLifecycle('missing', { status: 'inProgress' } as PatchEventLifecycleDto, auth('u1')),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('throws ForbiddenException when caller is not organizer', async () => {
    findUnique.mockResolvedValue({
      id: 'e1',
      organizerId: 'org-1',
      status: CleanupEventStatus.APPROVED,
      lifecycleStatus: EcoEventLifecycleStatus.UPCOMING,
      scheduledAt: new Date('2020-01-01T00:00:00Z'),
    });
    await expect(
      service.patchLifecycle(
        'e1',
        { status: 'inProgress' } as PatchEventLifecycleDto,
        auth('other-user'),
      ),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });
});
