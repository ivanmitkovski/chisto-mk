/// <reference types="jest" />

import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  GoneException,
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
import {
  POINTS_EVENT_CHECK_IN,
  REASON_EVENT_CHECK_IN,
} from '../../src/gamification/gamification.constants';

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
      findUnique: jest.Mock;
      deleteMany: jest.Mock;
    };
    eventParticipant: { findUnique: jest.Mock };
    user: { findUnique: jest.Mock };
    $transaction: jest.Mock;
  };
  let config: { get: jest.Mock };
  let ecoEventPoints: { creditIfNew: jest.Mock };
  let pendingCheckIn: {
    createPending: jest.Mock;
    getPending: jest.Mock;
    deletePending: jest.Mock;
    confirmTtlSec: number;
  };
  let checkInGateway: { emitToRoom: jest.Mock };
  let reportsUpload: { signPrivateObjectKey: jest.Mock };
  let checkInTelemetry: {
    emitMetric: jest.Mock;
    emitSpan: jest.Mock;
    emitAudit: jest.Mock;
  };
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
    pendingCheckIn = {
      createPending: jest.fn().mockResolvedValue({
        pendingId: 'pending-1',
        eventId: 'evt-1',
        userId: 'att-1',
        firstName: 'Test',
        lastName: 'User',
        avatarUrl: null,
        createdAt: '2026-04-16T12:00:00.000Z',
        expiresAt: '2026-04-16T12:01:00.000Z',
      }),
      getPending: jest.fn(),
      deletePending: jest.fn().mockResolvedValue(undefined),
      confirmTtlSec: 60,
    };
    checkInGateway = { emitToRoom: jest.fn() };
    reportsUpload = { signPrivateObjectKey: jest.fn().mockResolvedValue(null) };
    checkInTelemetry = {
      emitMetric: jest.fn(),
      emitSpan: jest.fn(),
      emitAudit: jest.fn(),
    };
    prisma = {
      cleanupEvent: {
        findFirst: jest.fn(),
        findUnique: jest.fn(),
        update: jest.fn().mockResolvedValue({}),
      },
      eventCheckIn: {
        findMany: jest.fn().mockResolvedValue([]),
        findUnique: jest.fn().mockResolvedValue(null),
        deleteMany: jest.fn(),
      },
      eventParticipant: { findUnique: jest.fn() },
      user: {
        findUnique: jest
          .fn()
          .mockResolvedValue({ firstName: 'Test', lastName: 'User', avatarObjectKey: null }),
      },
      $transaction: jest.fn(),
    };
    service = new EventsCheckInService(
      prisma as never,
      config as unknown as ConfigService,
      ecoEventPoints as never,
      pendingCheckIn as never,
      checkInGateway as never,
      reportsUpload as never,
      checkInTelemetry as never,
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
          user: {
            firstName: 'Ann',
            lastName: 'Bee',
            avatarObjectKey: 'avatars/u1.jpg',
          },
        },
      ]);
      reportsUpload.signPrivateObjectKey.mockResolvedValue('https://signed.example/a.jpg');
      const out = await service.listAttendees('evt-1', user('org-1'));
      expect(out.data).toHaveLength(1);
      expect(out.data[0].name).toBe('Ann Bee');
      expect(out.data[0].checkedInAt).toBe('2026-01-01T12:00:00.000Z');
      expect(out.data[0].avatarUrl).toBe('https://signed.example/a.jpg');
      expect(reportsUpload.signPrivateObjectKey).toHaveBeenCalledWith('avatars/u1.jpg');
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
      expect(ecoEventPoints.creditIfNew).toHaveBeenCalledWith(
        expect.anything(),
        expect.objectContaining({
          userId: 'vol-1',
          delta: POINTS_EVENT_CHECK_IN,
          reasonCode: REASON_EVENT_CHECK_IN,
          referenceType: 'CleanupEvent',
          referenceId: 'evt-1',
        }),
      );
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

    it('returns pending_confirmation on valid redeem', async () => {
      prisma.cleanupEvent.findFirst.mockResolvedValue({
        ...approvedInProgressEvent,
        organizerId: 'org-1',
      });
      prisma.eventParticipant.findUnique.mockResolvedValue({ id: 'part-1' });
      prisma.eventCheckIn.findUnique.mockResolvedValue(null);
      const nowSec = Math.floor(Date.now() / 1000);
      const jti = newCheckInJti();
      const qr = signCheckInQrToken(TEST_SECRET, {
        e: 'evt-1',
        s: 'session-stable-id',
        j: jti,
        iat: nowSec,
        exp: nowSec + CHECK_IN_QR_TTL_SEC,
      });
      prisma.$transaction.mockImplementation(async (fn: (tx: never) => Promise<unknown>) => {
        const tx = {
          eventCheckInRedemption: {
            create: jest.fn().mockResolvedValue({}),
          },
        };
        return fn(tx as never);
      });
      const out = await service.redeem('evt-1', user('att-1'), qr);
      expect(out.status).toBe('pending_confirmation');
      expect(out.pendingId).toBe('pending-1');
      expect(out.expiresAt).toBeTruthy();
      expect(pendingCheckIn.createPending).toHaveBeenCalledWith(
        'evt-1',
        'att-1',
        'Test',
        'User',
        null,
      );
      expect(checkInGateway.emitToRoom).toHaveBeenCalledWith(
        'evt-1',
        'checkin:request',
        expect.objectContaining({
          pendingId: 'pending-1',
          eventId: 'evt-1',
          userId: 'att-1',
          avatarUrl: null,
        }),
      );
    });

    it('returns already_checked_in when user has existing check-in', async () => {
      prisma.cleanupEvent.findFirst.mockResolvedValue({
        ...approvedInProgressEvent,
        organizerId: 'org-1',
      });
      prisma.eventParticipant.findUnique.mockResolvedValue({ id: 'part-1' });
      const checkedAt = new Date('2026-03-01T15:00:00Z');
      prisma.eventCheckIn.findUnique.mockResolvedValue({ checkedInAt: checkedAt });
      const nowSec = Math.floor(Date.now() / 1000);
      const qr = signCheckInQrToken(TEST_SECRET, {
        e: 'evt-1',
        s: 'session-stable-id',
        j: newCheckInJti(),
        iat: nowSec,
        exp: nowSec + CHECK_IN_QR_TTL_SEC,
      });
      prisma.$transaction.mockImplementation(async (fn: (tx: never) => Promise<unknown>) => {
        const tx = {
          eventCheckInRedemption: {
            create: jest.fn().mockResolvedValue({}),
          },
        };
        return fn(tx as never);
      });
      const out = await service.redeem('evt-1', user('att-1'), qr);
      expect(out.status).toBe('already_checked_in');
      expect(out.checkedInAt).toBe(checkedAt.toISOString());
      expect(out.pointsAwarded).toBe(0);
      expect(pendingCheckIn.createPending).not.toHaveBeenCalled();
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

  describe('resolveCheckIn', () => {
    it('throws GoneException when pending is expired', async () => {
      prisma.cleanupEvent.findFirst.mockResolvedValue(approvedInProgressEvent);
      pendingCheckIn.getPending.mockResolvedValue(null);
      await expect(
        service.resolveCheckIn('evt-1', 'expired-id', user('org-1'), 'approve'),
      ).rejects.toBeInstanceOf(GoneException);
    });

    it('throws NotFoundException when pending belongs to another event', async () => {
      prisma.cleanupEvent.findFirst.mockResolvedValue(approvedInProgressEvent);
      pendingCheckIn.getPending.mockResolvedValue({
        pendingId: 'p1',
        eventId: 'other-event',
        userId: 'att-1',
        firstName: 'Test',
        lastName: 'User',
        createdAt: '2026-04-16T12:00:00.000Z',
        expiresAt: '2026-04-16T12:01:00.000Z',
      });
      await expect(
        service.resolveCheckIn('evt-1', 'p1', user('org-1'), 'approve'),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it('reject emits checkin:rejected and deletes pending', async () => {
      prisma.cleanupEvent.findFirst.mockResolvedValue(approvedInProgressEvent);
      pendingCheckIn.getPending.mockResolvedValue({
        pendingId: 'p1',
        eventId: 'evt-1',
        userId: 'att-1',
        firstName: 'Test',
        lastName: 'User',
        createdAt: '2026-04-16T12:00:00.000Z',
        expiresAt: '2026-04-16T12:01:00.000Z',
      });
      const result = await service.resolveCheckIn('evt-1', 'p1', user('org-1'), 'reject');
      expect(result).toBeNull();
      expect(pendingCheckIn.deletePending).toHaveBeenCalledWith('p1');
      expect(checkInGateway.emitToRoom).toHaveBeenCalledWith(
        'evt-1',
        'checkin:rejected',
        expect.objectContaining({ pendingId: 'p1', userId: 'att-1' }),
      );
    });

    it('approve creates check-in, awards points, emits checkin:confirmed', async () => {
      prisma.cleanupEvent.findFirst.mockResolvedValue(approvedInProgressEvent);
      pendingCheckIn.getPending.mockResolvedValue({
        pendingId: 'p1',
        eventId: 'evt-1',
        userId: 'att-1',
        firstName: 'Test',
        lastName: 'User',
        createdAt: '2026-04-16T12:00:00.000Z',
        expiresAt: '2026-04-16T12:01:00.000Z',
      });
      const checkedAt = new Date('2026-04-16T12:00:30Z');
      prisma.$transaction.mockImplementation(async (fn: (tx: never) => Promise<unknown>) => {
        const tx = {
          eventCheckIn: {
            findUnique: jest.fn().mockResolvedValue(null),
            create: jest.fn().mockResolvedValue({ id: 'cin-1', checkedInAt: checkedAt }),
          },
          cleanupEvent: { update: jest.fn().mockResolvedValue({}) },
        };
        ecoEventPoints.creditIfNew.mockResolvedValue(POINTS_EVENT_CHECK_IN);
        return fn(tx as never);
      });
      const result = await service.resolveCheckIn('evt-1', 'p1', user('org-1'), 'approve');
      expect(result).not.toBeNull();
      expect(result!.checkedInAt).toBe(checkedAt.toISOString());
      expect(result!.pointsAwarded).toBe(POINTS_EVENT_CHECK_IN);
      expect(result!.userId).toBe('att-1');
      expect(result!.displayName).toBe('Test User');
      expect(pendingCheckIn.deletePending).toHaveBeenCalledWith('p1');
      expect(checkInGateway.emitToRoom).toHaveBeenCalledWith(
        'evt-1',
        'checkin:confirmed',
        expect.objectContaining({
          pendingId: 'p1',
          userId: 'att-1',
          pointsAwarded: POINTS_EVENT_CHECK_IN,
        }),
      );
      expect(ecoEventPoints.creditIfNew).toHaveBeenCalledWith(
        expect.anything(),
        expect.objectContaining({
          userId: 'att-1',
          delta: POINTS_EVENT_CHECK_IN,
          reasonCode: REASON_EVENT_CHECK_IN,
          referenceType: 'CleanupEvent',
          referenceId: 'evt-1',
        }),
      );
    });

    it('approve is idempotent when user already checked in', async () => {
      prisma.cleanupEvent.findFirst.mockResolvedValue(approvedInProgressEvent);
      pendingCheckIn.getPending.mockResolvedValue({
        pendingId: 'p1',
        eventId: 'evt-1',
        userId: 'att-1',
        firstName: 'Test',
        lastName: 'User',
        createdAt: '2026-04-16T12:00:00.000Z',
        expiresAt: '2026-04-16T12:01:00.000Z',
      });
      const existingCheckedAt = new Date('2026-04-16T11:50:00Z');
      prisma.$transaction.mockImplementation(async (fn: (tx: never) => Promise<unknown>) => {
        const tx = {
          eventCheckIn: {
            findUnique: jest.fn().mockResolvedValue({
              id: 'cin-existing',
              checkedInAt: existingCheckedAt,
            }),
          },
        };
        return fn(tx as never);
      });
      const result = await service.resolveCheckIn('evt-1', 'p1', user('org-1'), 'approve');
      expect(result).not.toBeNull();
      expect(result!.pointsAwarded).toBe(0);
      expect(ecoEventPoints.creditIfNew).not.toHaveBeenCalled();
    });
  });

  describe('getPendingStatus', () => {
    it('returns expired when pending is missing', async () => {
      pendingCheckIn.getPending.mockResolvedValue(null);
      await expect(service.getPendingStatus('evt-1', 'p1', user('att-1'))).resolves.toEqual({
        status: 'expired',
      });
    });

    it('returns pending when event id and caller match the stored pending row', async () => {
      pendingCheckIn.getPending.mockResolvedValue({
        pendingId: 'p1',
        eventId: 'evt-1',
        userId: 'att-1',
        firstName: 'A',
        lastName: 'B',
        createdAt: '2026-04-16T12:00:00.000Z',
        expiresAt: '2026-04-16T12:01:00.000Z',
      });
      await expect(service.getPendingStatus('evt-1', 'p1', user('att-1'))).resolves.toEqual({
        status: 'pending',
        expiresAt: '2026-04-16T12:01:00.000Z',
      });
    });

    it('throws NotFound when pending belongs to another event', async () => {
      pendingCheckIn.getPending.mockResolvedValue({
        pendingId: 'p1',
        eventId: 'evt-other',
        userId: 'att-1',
        firstName: 'A',
        lastName: 'B',
        createdAt: '2026-04-16T12:00:00.000Z',
        expiresAt: '2026-04-16T12:01:00.000Z',
      });
      let err: unknown;
      try {
        await service.getPendingStatus('evt-1', 'p1', user('att-1'));
      } catch (e) {
        err = e;
      }
      expect(err).toBeInstanceOf(NotFoundException);
      expect((err as NotFoundException).getResponse()).toEqual(
        expect.objectContaining({
          code: 'CHECK_IN_REQUEST_NOT_FOUND',
          message: 'Pending check-in request not found',
        }),
      );
    });

    it('throws NotFound when pending user does not match caller', async () => {
      pendingCheckIn.getPending.mockResolvedValue({
        pendingId: 'p1',
        eventId: 'evt-1',
        userId: 'other-user',
        firstName: 'A',
        lastName: 'B',
        createdAt: '2026-04-16T12:00:00.000Z',
        expiresAt: '2026-04-16T12:01:00.000Z',
      });
      await expect(service.getPendingStatus('evt-1', 'p1', user('att-1'))).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });
  });
});
