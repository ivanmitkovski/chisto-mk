import { BadRequestException, ForbiddenException, NotFoundException } from '@nestjs/common';
import {
  CleanupEventStatus,
  EcoEventLifecycleStatus,
} from '../../src/prisma-client';
import {
  assertQrTokenVerifiedForRedeem,
  assertRedeemEligibleEventAndUser,
} from '../../src/events/check-in-redemption-validator';

describe('check-in-redemption-validator', () => {
  const baseEvent = {
    organizerId: 'org-1',
    status: CleanupEventStatus.APPROVED,
    lifecycleStatus: EcoEventLifecycleStatus.IN_PROGRESS,
    checkInSessionId: 'sess-1',
    checkInOpen: true,
  };

  describe('assertRedeemEligibleEventAndUser', () => {
    it('throws NotFound when event is null', () => {
      expect(() =>
        assertRedeemEligibleEventAndUser(null, { userId: 'u1', isParticipant: true }),
      ).toThrow(NotFoundException);
    });

    it('throws Forbidden when organizer self check-in', () => {
      expect(() =>
        assertRedeemEligibleEventAndUser(baseEvent, {
          userId: 'org-1',
          isParticipant: true,
        }),
      ).toThrow(ForbiddenException);
    });

    it('throws Forbidden when not a participant', () => {
      expect(() =>
        assertRedeemEligibleEventAndUser(baseEvent, {
          userId: 'u1',
          isParticipant: false,
        }),
      ).toThrow(ForbiddenException);
    });

    it('passes for eligible volunteer', () => {
      expect(() =>
        assertRedeemEligibleEventAndUser(baseEvent, {
          userId: 'u1',
          isParticipant: true,
        }),
      ).not.toThrow();
    });
  });

  describe('assertQrTokenVerifiedForRedeem', () => {
    it('throws on failed verification', () => {
      expect(() =>
        assertQrTokenVerifiedForRedeem({ ok: false, reason: 'INVALID_FORMAT' }, 'evt', 'sess'),
      ).toThrow(BadRequestException);
    });

    it('throws on wrong event id', () => {
      expect(() =>
        assertQrTokenVerifiedForRedeem(
          {
            ok: true,
            claims: {
              e: 'other',
              s: 'sess',
              j: 'jti',
              iat: 1,
              exp: 2,
            },
          },
          'evt',
          'sess',
        ),
      ).toThrow(BadRequestException);
    });

    it('passes when claims match', () => {
      expect(() =>
        assertQrTokenVerifiedForRedeem(
          {
            ok: true,
            claims: {
              e: 'evt',
              s: 'sess',
              j: 'jti',
              iat: 1,
              exp: 2,
            },
          },
          'evt',
          'sess',
        ),
      ).not.toThrow();
    });
  });
});
