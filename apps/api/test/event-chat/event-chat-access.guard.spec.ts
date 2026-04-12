/// <reference types="jest" />

import { ExecutionContext, ForbiddenException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../src/prisma/prisma.service';
import type { AuthenticatedUser } from '../../src/auth/types/authenticated-user.type';
import { EventChatAccessGuard } from '../../src/event-chat/event-chat-access.guard';
import { EventChatAccessService } from '../../src/event-chat/event-chat-access.service';

function ctx(user: AuthenticatedUser | undefined, eventId: string): ExecutionContext {
  return {
    switchToHttp: () => ({
      getRequest: () => ({
        user,
        params: { eventId },
      }),
    }),
  } as ExecutionContext;
}

describe('EventChatAccessGuard', () => {
  let prisma: {
    cleanupEvent: { findFirst: jest.Mock };
    eventParticipant: { findUnique: jest.Mock };
  };
  let guard: EventChatAccessGuard;

  const user: AuthenticatedUser = {
    userId: 'u1',
    email: 'a@b.c',
    phoneNumber: '+100',
    role: 'USER' as const,
  };

  beforeEach(() => {
    prisma = {
      cleanupEvent: { findFirst: jest.fn() },
      eventParticipant: { findUnique: jest.fn() },
    };
    const access = new EventChatAccessService(prisma as unknown as PrismaService);
    guard = new EventChatAccessGuard(access);
  });

  it('throws when user missing', async () => {
    await expect(guard.canActivate(ctx(undefined, 'e1'))).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('throws not found when event missing', async () => {
    prisma.cleanupEvent.findFirst.mockResolvedValue(null);
    await expect(guard.canActivate(ctx(user, 'e1'))).rejects.toBeInstanceOf(NotFoundException);
  });

  it('allows organizer without participant row', async () => {
    prisma.cleanupEvent.findFirst.mockResolvedValue({
      id: 'e1',
      organizerId: user.userId,
    });
    const ok = await guard.canActivate(ctx(user, 'e1'));
    expect(ok).toBe(true);
    expect(prisma.eventParticipant.findUnique).not.toHaveBeenCalled();
  });

  it('allows approved event participant', async () => {
    prisma.cleanupEvent.findFirst.mockResolvedValue({
      id: 'e1',
      organizerId: 'org',
    });
    prisma.eventParticipant.findUnique.mockResolvedValue({ id: 'p1' });
    const ok = await guard.canActivate(ctx(user, 'e1'));
    expect(ok).toBe(true);
  });

  it('forbids non-organizer without join', async () => {
    prisma.cleanupEvent.findFirst.mockResolvedValue({
      id: 'e1',
      organizerId: 'org',
    });
    prisma.eventParticipant.findUnique.mockResolvedValue(null);
    await expect(guard.canActivate(ctx(user, 'e1'))).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('finds pending organizer-owned event for organizer', async () => {
    prisma.cleanupEvent.findFirst.mockResolvedValue({
      id: 'e1',
      organizerId: user.userId,
    });
    await expect(guard.canActivate(ctx(user, 'e1'))).resolves.toBe(true);
  });
});
