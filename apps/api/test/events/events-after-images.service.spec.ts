/// <reference types="jest" />

import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { CleanupEventStatus } from '../../src/prisma-client';
import type { AuthenticatedUser } from '../../src/auth/types/authenticated-user.type';
import { EventsAfterImagesService } from '../../src/events/events-after-images.service';
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

describe('EventsAfterImagesService', () => {
  let service: EventsAfterImagesService;
  let findUnique: jest.Mock;

  beforeEach(() => {
    findUnique = jest.fn();
    const prisma = {
      cleanupEvent: { findUnique, update: jest.fn() },
    };
    const repo = { prisma } as unknown as EventsRepository;
    const mobileMapper = { toMobileEvent: jest.fn((e: unknown) => e) } as unknown as EventsMobileMapperService;
    const cleanupMediaUpload = { uploadCleanupEventAfterImages: jest.fn() };
    service = new EventsAfterImagesService(repo, cleanupMediaUpload as never, mobileMapper);
  });

  it('throws NotFoundException when event missing', async () => {
    findUnique.mockResolvedValue(null);
    await expect(service.appendAfterImages('x', [], auth('u1'))).rejects.toBeInstanceOf(NotFoundException);
  });

  it('throws ForbiddenException when user is not organizer', async () => {
    findUnique.mockResolvedValue({
      id: 'e1',
      organizerId: 'org-1',
      status: CleanupEventStatus.APPROVED,
      afterImageKeys: [],
    });
    await expect(service.appendAfterImages('e1', [], auth('u2'))).rejects.toBeInstanceOf(ForbiddenException);
  });
});
