/// <reference types="jest" />

import { Reflector } from '@nestjs/core';
import type { ThrottlerStorage } from '@nestjs/throttler/dist/throttler-storage.interface';
import type { AuthenticatedUser } from '../../src/auth/types/authenticated-user.type';
import { EventChatThrottlerGuard } from '../../src/event-chat/event-chat-throttler.guard';

describe('EventChatThrottlerGuard', () => {
  const storage: ThrottlerStorage = {
    increment: jest.fn().mockResolvedValue({
      totalHits: 1,
      timeToExpire: 60_000,
      isBlocked: false,
      timeToBlockExpire: 0,
    }),
  };

  const guard = new EventChatThrottlerGuard(
    [{ name: 'default', ttl: 60_000, limit: 100 }],
    storage,
    new Reflector(),
  );

  const user: AuthenticatedUser = {
    userId: 'u1',
    email: 'a@b.c',
    phoneNumber: '+100',
    role: 'USER' as const,
  };

  it('tracks per user and eventId when both are present', async () => {
    const key = await guard['getTracker']({
      user,
      params: { eventId: 'evt-99' },
      ip: '1.2.3.4',
    } as never);
    expect(key).toBe('u:u1:evt:evt-99');
  });

  it('falls back to user-only tracker when eventId missing', async () => {
    const key = await guard['getTracker']({
      user,
      params: {},
      ip: '1.2.3.4',
    } as never);
    expect(key).toBe('u:u1');
  });

  it('falls back to ip when user missing', async () => {
    const key = await guard['getTracker']({
      params: { eventId: 'evt-99' },
      ip: '9.9.9.9',
    } as never);
    expect(key).toBe('ip:9.9.9.9');
  });
});
