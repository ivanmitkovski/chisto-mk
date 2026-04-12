/// <reference types="jest" />

import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  CleanupEventStatus,
  EcoEventLifecycleStatus,
  Prisma,
  Role,
} from '../../src/prisma-client';
import type { AuthenticatedUser } from '../../src/auth/types/authenticated-user.type';
import {
  CHECK_IN_QR_TTL_SEC,
  newCheckInJti,
  signCheckInQrToken,
} from '../../src/events/check-in-qr-token';
import { EventsCheckInService } from '../../src/events/events-check-in.service';

function user(id: string, role: Role = Role.USER): AuthenticatedUser {
  return {
    userId: id,
    email: `${id}@test.chisto.mk`,
    phoneNumber: '+38970000000',
    role,
  };
}

const TEST_SECRET = Buffer.from('test_check_in_qr_secret_min_24c', 'utf8');

describe('EventsCheckInService', () => {
  let prisma: {
    cleanupEvent: {
      findFirst: jest.Mock;
      findUnique: jest.Mock;
      update: jest.Mock;
    };
    eventCheckIn: {
      findMany: jest.Mock;
      deleteMany: jest.Mock;
    };
    eventParticipant: { findUnique: jest.Mock };
    user: { findUnique: jest.Mock };
    $transaction: jest.Mock;
  };
  let config: { get: jest.Mock };
  let ecoEventPoints: { creditIfNew: jest.Mock };
  let service: EventsCheckInService;

  const approvedInProgressEvent = {
    id: 'evt-1',
    organizerId: 'org-1',
    lifecycleStatus: EcoEventLifecycleStatus.IN_PROGRESS,
    status: CleanupEventStatus.APPROVED,
    checkInSessionId: 'session-stable-id',
    checkInOpen: true,
  };

  beforeEach(() => {
    config = {
      get: jest.fn((key: string) => {
        if (key === 'CHECK_IN_QR_SECRET') return TEST_SECRET.toString('utf8');
        if (key === 'NODE_ENV') return 'test';
        return undefined;
      }),
    };
    ecoEventPoints = { creditIfNew: jest.fn().mockResolvedValue(5) };
    prisma = {
      cleanupEvent: {
        findFirst: jest.fn(),
        findUnique: jest.fn(),
        update: jest.fn().mockResolvedValue({}),
      },
      eventCheckIn: {
        findMany: jest.fn().mockResolvedValue([]),
        deleteMany: jest.fn(),
      },
      eventParticipant: { findUnique: jest.fn() },
      user: { findUnique: jest.fn() },
      $transaction: jest.fn(),
    };
    service = new EventsCheckInService(
      prisma as never,
      config as unknown as ConfigService,
      ecoEventPoints as never,
    );
  });

  describe('patchOpen', () => {
    it('throws when event is not in progress', async () => {
      prisma.cleanupEvent.findFirst.mockResolvedValue({
        ...approvedInProgressEvent,
        lifecycleStatus: EcoEventLifecycleStatus.UPCOMING,
      });
      await expect(
        service.patchOpen('evt-1', user('org-1'), true),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('sets session id when opening and session was null', async () => {
      prisma.cleanupEvent.findFirst.mockResolvedValue({
        ...approvedInProgressEvent,
        checkInSessionId: null,
      });
      await service.patchOpen('evt-1', user('org-1'), true);
      expect(prisma.cleanupEvent.update).toHaveBeenCalledWith({
        where: { id: 'evt-1' },
        data: expect.objectContaining({
          checkInOpen: true,
          checkInSessionId: expect.any(String),
        }),
      });
    });

    it('throws when caller is not the event organizer', async () => {
      prisma.cleanupEvent.findFirst.mockResolvedValue(approvedInProgressEvent);
      await expect(
        service.patchOpen('evt-1', user('other'), true),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });
  });

  describe('rotateSession', () => {
    it('updates session id for approved in-progress event', async () => {
      prisma.cleanupEvent.findFirst.mockResolvedValue(approvedInProgressEvent);
      await service.rotateSession('evt-1', user('org-1'));
      expect(prisma.cleanupEvent.update).toHaveBeenCalledWith({
        where: { id: 'evt-1' },
        data: { checkInSessionId: expect.any(String) },
      });
    });
  });

  describe('getQrPayload', () => {
    it('throws CHECK_IN_SESSION_CLOSED when check-in not open', async () => {
      prisma.cleanupEvent.findFirst.mockResolvedValue({
        ...approvedInProgressEvent,
        checkInOpen: false,
      });
      await expect(service.getQrPayload('evt-1', user('org-1'))).rejects.toMatchObject({
        response: expect.objectContaining({ code: 'CHECK_IN_SESSION_CLOSED' }),
      });
    });

    it('returns signed qrPayload when session is active', async () => {
      prisma.cleanupEvent.findFirst.mockResolvedValue(approvedInProgressEvent);
      const out = await service.getQrPayload('evt-1', user('org-1'));
      expect(out.qrPayload).toContain('chisto:evt:v2:');
      expect(out.sessionId).toBe('session-stable-id');
      expect(out.expiresAt).toBeTruthy();
    });
  });

  describe('listAttendees', () => {
    it('maps rows to data array', async () => {
      prisma.cleanupEvent.findFirst.mockResolvedValue(approvedInProgressEvent);
      prisma.eventCheckIn.findMany.mockResolvedValue([
        {
          id: 'c1',
          dedupeKey: 'u:u1',
          userId: 'u1',
          guestDisplayName: null,
          checkedInAt: new Date('2026-01-01T12:00:00Z'),
          user: { firstName: 'Ann', lastName: 'Bee' },
        },
      ]);
      const out = await service.listAttendees('evt-1', user('org-1'));
      expect(out.data).toHaveLength(1);
      expect(out.data[0].name).toBe('Ann Bee');
      expect(out.data[0].checkedInAt).toBe('2026-01-01T12:00:00.000Z');
    });
  });

  describe('manualAdd', () => {
    it('throws CHECK_IN_REQUIRES_JOIN when user is not a participant', async () => {
      prisma.cleanupEvent.findFirst.mockResolvedValue(approvedInProgressEvent);
      prisma.$transaction.mockImplementation(async (fn: (tx: never) => Promise<unknown>) => {
        const tx = {
          eventParticipant: {
            findUnique: jest.fn().mockResolvedValue(null),
          },
        };
        return fn(tx as never);
      });
      await expect(
        service.manualAdd('evt-1', user('org-1'), { userId: 'vol-1' }),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });

    it('throws CHECK_IN_ALREADY_RECORDED when check-in exists', async () => {
      prisma.cleanupEvent.findFirst.mockResolvedValue(approvedInProgressEvent);
      prisma.$transaction.mockImplementation(async (fn: (tx: never) => Promise<unknown>) => {
        const tx = {
          eventParticipant: {
            findUnique: jest.fn().mockResolvedValue({ id: 'p1' }),
          },
          eventCheckIn: {
            findUnique: jest.fn().mockResolvedValue({ id: 'existing' }),
          },
        };
        return fn(tx as never);
      });
      await expect(
        service.manualAdd('evt-1', user('org-1'), { userId: 'vol-1' }),
      ).rejects.toBeInstanceOf(ConflictException);
    });

    it('creates check-in and returns pointsAwarded', async () => {
      prisma.cleanupEvent.findFirst.mockResolvedValue(approvedInProgressEvent);
      const checkedAt = new Date('2026-01-02T10:00:00Z');
      prisma.$transaction.mockImplementation(async (fn: (tx: never) => Promise<unknown>) => {
        const tx = {
          eventParticipant: {
            findUnique: jest.fn().mockResolvedValue({ id: 'p1' }),
          },
          eventCheckIn: {
            findUnique: jest.fn().mockResolvedValue(null),
            create: jest
              .fn()
              .mockResolvedValue({ id: 'cin-1', checkedInAt: checkedAt }),
          },
          cleanupEvent: { update: jest.fn().mockResolvedValue({}) },
          user: {
            findUnique: jest
              .fn()
              .mockResolvedValue({ firstName: 'Vol', lastName: 'One' }),
          },
        };
        ecoEventPoints.creditIfNew.mockResolvedValue(7);
        return fn(tx as never);
      });
      const out = await service.manualAdd('evt-1', user('org-1'), {
        userId: 'vol-1',
      });
      expect(out.id).toBe('cin-1');
      expect(out.pointsAwarded).toBe(7);
      expect(out.name).toBe('Vol One');
    });
  });

  describe('removeAttendee', () => {
    it('throws when no row deleted', async () => {
      prisma.cleanupEvent.findFirst.mockResolvedValue(approvedInProgressEvent);
      prisma.$transaction.mockImplementation(async (fn: (tx: never) => Promise<unknown>) => {
        const tx = {
          eventCheckIn: {
            deleteMany: jest.fn().mockResolvedValue({ count: 0 }),
          },
          cleanupEvent: { update: jest.fn() },
        };
        return fn(tx as never);
      });
      await expect(
        service.removeAttendee('evt-1', 'missing', user('org-1')),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it('decrements count when delete succeeds', async () => {
      prisma.cleanupEvent.findFirst.mockResolvedValue(approvedInProgressEvent);
      prisma.cleanupEvent.findUnique.mockResolvedValue({ checkedInCount: 3 });
      prisma.$transaction.mockImplementation(async (fn: (tx: never) => Promise<unknown>) => {
        const tx = {
          eventCheckIn: {
            deleteMany: jest.fn().mockResolvedValue({ count: 1 }),
          },
          cleanupEvent: { update: jest.fn().mockResolvedValue({}) },
        };
        return fn(tx as never);
      });
      await service.removeAttendee('evt-1', 'cin-1', user('org-1'));
      expect(prisma.$transaction).toHaveBeenCalled();
    });
  });

  describe('redeem', () => {
    it('forbids organizer self check-in', async () => {
      prisma.cleanupEvent.findFirst.mockResolvedValue({
        ...approvedInProgressEvent,
        organizerId: 'org-1',
      });
      await expect(
        service.redeem('evt-1', user('org-1'), 'any'),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });

    it('throws CHECK_IN_REQUIRES_JOIN when not a participant', async () => {
      prisma.cleanupEvent.findFirst.mockResolvedValue({
        ...approvedInProgressEvent,
        organizerId: 'org-1',
      });
      prisma.eventParticipant.findUnique.mockResolvedValue(null);
      const qr = signCheckInQrToken(TEST_SECRET, {
        e: 'evt-1',
        s: 'session-stable-id',
        j: newCheckInJti(),
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + CHECK_IN_QR_TTL_SEC,
      });
      await expect(
        service.redeem('evt-1', user('att-1'), qr),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });

    it('returns checkedInAt and points on success', async () => {
      prisma.cleanupEvent.findFirst.mockResolvedValue({
        ...approvedInProgressEvent,
        organizerId: 'org-1',
      });
      prisma.eventParticipant.findUnique.mockResolvedValue({ id: 'part-1' });
      const nowSec = Math.floor(Date.now() / 1000);
      const jti = newCheckInJti();
      const qr = signCheckInQrToken(TEST_SECRET, {
        e: 'evt-1',
        s: 'session-stable-id',
        j: jti,
        iat: nowSec,
        exp: nowSec + CHECK_IN_QR_TTL_SEC,
      });
      const checkedAt = new Date('2026-03-01T15:00:00Z');
      prisma.$transaction.mockImplementation(async (fn: (tx: never) => Promise<unknown>) => {
        const tx = {
          eventCheckInRedemption: {
            create: jest.fn().mockResolvedValue({}),
          },
          eventCheckIn: {
            findUnique: jest.fn().mockResolvedValue(null),
            create: jest
              .fn()
              .mockResolvedValue({ id: 'row-1', checkedInAt: checkedAt }),
          },
          cleanupEvent: { update: jest.fn().mockResolvedValue({}) },
        };
        ecoEventPoints.creditIfNew.mockResolvedValue(12);
        return fn(tx as never);
      });
      const out = await service.redeem('evt-1', user('att-1'), qr);
      expect(out.pointsAwarded).toBe(12);
      expect(out.checkedInAt).toBe(checkedAt.toISOString());
    });

    it('throws ConflictException on replay (redemption jti duplicate)', async () => {
      prisma.cleanupEvent.findFirst.mockResolvedValue({
        ...approvedInProgressEvent,
        organizerId: 'org-1',
      });
      prisma.eventParticipant.findUnique.mockResolvedValue({ id: 'part-1' });
      const nowSec = Math.floor(Date.now() / 1000);
      const jti = newCheckInJti();
      const qr = signCheckInQrToken(TEST_SECRET, {
        e: 'evt-1',
        s: 'session-stable-id',
        j: jti,
        iat: nowSec,
        exp: nowSec + CHECK_IN_QR_TTL_SEC,
      });
      const p2002 = new Prisma.PrismaClientKnownRequestError('dup', {
        code: 'P2002',
        clientVersion: 'test',
      });
      prisma.$transaction.mockImplementation(async (fn: (tx: never) => Promise<unknown>) => {
        const tx = {
          eventCheckInRedemption: {
            create: jest.fn().mockRejectedValue(p2002),
          },
        };
        return fn(tx as never);
      });
      await expect(service.redeem('evt-1', user('att-1'), qr)).rejects.toBeInstanceOf(
        ConflictException,
      );
    });

    it('throws CHECK_IN_SESSION_MISMATCH when QR session does not match event', async () => {
      prisma.cleanupEvent.findFirst.mockResolvedValue({
        ...approvedInProgressEvent,
        organizerId: 'org-1',
      });
      prisma.eventParticipant.findUnique.mockResolvedValue({ id: 'part-1' });
      const nowSec = Math.floor(Date.now() / 1000);
      const qr = signCheckInQrToken(TEST_SECRET, {
        e: 'evt-1',
        s: 'other-session',
        j: newCheckInJti(),
        iat: nowSec,
        exp: nowSec + CHECK_IN_QR_TTL_SEC,
      });
      await expect(service.redeem('evt-1', user('att-1'), qr)).rejects.toMatchObject({
        response: expect.objectContaining({ code: 'CHECK_IN_SESSION_MISMATCH' }),
      });
    });
  });
});
