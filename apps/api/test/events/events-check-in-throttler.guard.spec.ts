/// <reference types="jest" />

import { Reflector } from '@nestjs/core';
import type { ThrottlerModuleOptions } from '@nestjs/throttler';
import type { ThrottlerStorage } from '@nestjs/throttler';
import { Role } from '../../src/prisma-client';
import { EventsCheckInThrottlerGuard } from '../../src/events/events-check-in-throttler.guard';

describe('EventsCheckInThrottlerGuard', () => {
  const storage: ThrottlerStorage = {
    increment: jest.fn().mockResolvedValue({
      totalHits: 1,
      timeToExpire: 60,
      isBlocked: false,
      timeToBlockExpire: 0,
    }),
  };

  const options: ThrottlerModuleOptions = {
    throttlers: [{ name: 'default', ttl: 60_000, limit: 100 }],
  };

  const guard = new EventsCheckInThrottlerGuard(options, storage, new Reflector());

  it('getTracker prefers authenticated user id', async () => {
    const req = {
      user: {
        userId: 'user-cuid-1',
        email: 'a@b.mk',
        phoneNumber: '+38970000000',
        role: Role.USER,
      },
      ip: '10.0.0.1',
    };
    const key = await guard['getTracker'](req);
    expect(key).toBe('u:user-cuid-1');
  });

  it('getTracker falls back to ip when user absent', async () => {
    const req = { ip: '192.168.1.2' };
    const key = await guard['getTracker'](req);
    expect(key).toBe('ip:192.168.1.2');
  });
});
