/// <reference types="jest" />

import {
  ForbiddenException,
  HttpException,
  InternalServerErrorException,
  NotFoundException,
} from '@nestjs/common';
import type { AuthenticatedUser } from '../../src/auth/types/authenticated-user.type';
import { EventsCheckInSharedService } from '../../src/events/events-check-in-shared.service';

function auth(userId: string): AuthenticatedUser {
  return {
    userId,
    email: `${userId}@test.chisto.mk`,
    phoneNumber: '+38970000000',
    role: 'USER' as never,
  };
}

describe('EventsCheckInSharedService', () => {
  let findFirst: jest.Mock;
  let service: EventsCheckInSharedService;

  beforeEach(() => {
    findFirst = jest.fn();
    const checkInRepository = {
      prisma: { cleanupEvent: { findFirst } },
    };
    const config = {
      get: jest.fn((key: string) => {
        if (key === 'CHECK_IN_QR_SECRET') {
          return 'x'.repeat(24);
        }
        if (key === 'NODE_ENV') {
          return 'test';
        }
        return undefined;
      }),
    };
    service = new EventsCheckInSharedService(checkInRepository as never, config as never);
  });

  it('getCheckInSecret returns buffer from config when long enough', () => {
    const buf = service.getCheckInSecret();
    expect(buf.length).toBeGreaterThanOrEqual(24);
  });

  it('httpExceptionLabel returns code from structured body', () => {
    const err = new HttpException({ code: 'FOO', message: 'm' }, 400);
    expect(service.httpExceptionLabel(err)).toBe('FOO');
  });

  it('loadEventForOrganizer throws NotFound when missing', async () => {
    findFirst.mockResolvedValue(null);
    await expect(service.loadEventForOrganizer('e1', auth('u1'))).rejects.toBeInstanceOf(NotFoundException);
  });

  it('loadEventForOrganizer throws Forbidden when not organizer', async () => {
    findFirst.mockResolvedValue({
      id: 'e1',
      organizerId: 'org-1',
      lifecycleStatus: 'UPCOMING',
      status: 'APPROVED',
      checkInSessionId: null,
      checkInOpen: false,
    });
    await expect(service.loadEventForOrganizer('e1', auth('other'))).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('getCheckInSecret throws in production without secret', () => {
    const findFirstLocal = jest.fn();
    const svc = new EventsCheckInSharedService(
      { prisma: { cleanupEvent: { findFirst: findFirstLocal } } } as never,
      {
        get: jest.fn((key: string) => (key === 'NODE_ENV' ? 'production' : undefined)),
      } as never,
    );
    expect(() => svc.getCheckInSecret()).toThrow(InternalServerErrorException);
  });
});
