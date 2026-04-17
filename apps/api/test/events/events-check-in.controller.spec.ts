/// <reference types="jest" />

import { EventsCheckInController } from '../../src/events/events-check-in.controller';
import { EventsCheckInService } from '../../src/events/events-check-in.service';
import type { AuthenticatedUser } from '../../src/auth/types/authenticated-user.type';
import { Role } from '../../src/prisma-client';

describe('EventsCheckInController', () => {
  const organizer: AuthenticatedUser = {
    userId: 'org-1',
    email: 'org@test.chisto.mk',
    phoneNumber: '+38970000001',
    role: Role.USER,
  };

  it('GET qr delegates to service', async () => {
    const checkIn = {
      getQrPayload: jest.fn().mockResolvedValue({
        qrPayload: 'u:1.x',
        sessionId: 'sess',
        expiresAt: '2026-04-16T12:00:00.000Z',
        issuedAtMs: 1_000,
      }),
    } as unknown as EventsCheckInService;

    const controller = new EventsCheckInController(checkIn);
    const out = await controller.getQr('evt-1', organizer);
    expect(checkIn.getQrPayload).toHaveBeenCalledWith('evt-1', organizer);
    expect(out).toEqual(
      expect.objectContaining({
        qrPayload: 'u:1.x',
        sessionId: 'sess',
      }),
    );
  });

  it('GET pending/:pendingId delegates with eventId and authenticated user', async () => {
    const volunteer: AuthenticatedUser = {
      userId: 'vol-1',
      email: 'vol@test.chisto.mk',
      phoneNumber: '+38970000002',
      role: Role.USER,
    };
    const checkIn = {
      getPendingStatus: jest.fn().mockResolvedValue({
        status: 'pending' as const,
        expiresAt: '2026-04-16T12:01:00.000Z',
      }),
    } as unknown as EventsCheckInService;

    const controller = new EventsCheckInController(checkIn);
    const out = await controller.getPendingStatus('evt-1', 'pend-1', volunteer);
    expect(checkIn.getPendingStatus).toHaveBeenCalledWith('evt-1', 'pend-1', volunteer);
    expect(out).toEqual({
      status: 'pending',
      expiresAt: '2026-04-16T12:01:00.000Z',
    });
  });
});
