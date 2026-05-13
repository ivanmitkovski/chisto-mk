import {
  BadRequestException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import {
  CleanupEventStatus,
  EcoEventLifecycleStatus,
} from '../prisma-client';
import type { CheckInQrClaims, VerifyQrFailureReason } from './check-in-qr-token';

/** Minimal event row needed to validate a QR redeem attempt. */
export type RedeemEventSnapshot = {
  organizerId: string | null;
  status: CleanupEventStatus;
  lifecycleStatus: EcoEventLifecycleStatus;
  checkInSessionId: string | null;
  checkInOpen: boolean;
};

export function assertRedeemEligibleEventAndUser(
  event: RedeemEventSnapshot | null | undefined,
  options: { userId: string; isParticipant: boolean },
): asserts event is RedeemEventSnapshot {
  if (event == null) {
    throw new NotFoundException({
      code: 'EVENT_NOT_FOUND',
      message: 'Event not found',
    });
  }
  if (event.organizerId != null && event.organizerId === options.userId) {
    throw new ForbiddenException({
      code: 'ORGANIZER_CANNOT_CHECK_IN',
      message: 'Organizers use the organizer check-in tools',
    });
  }
  if (!options.isParticipant) {
    throw new ForbiddenException({
      code: 'CHECK_IN_REQUIRES_JOIN',
      message: 'Join the event before checking in',
    });
  }
  if (event.status !== CleanupEventStatus.APPROVED) {
    throw new BadRequestException({
      code: 'EVENT_NOT_JOINABLE',
      message: 'This event is not open for check-in',
    });
  }
  if (event.lifecycleStatus !== EcoEventLifecycleStatus.IN_PROGRESS) {
    throw new BadRequestException({
      code: 'CHECK_IN_LIFECYCLE',
      message: 'Check-in is not available for this event state',
    });
  }
  if (!event.checkInOpen) {
    throw new BadRequestException({
      code: 'CHECK_IN_SESSION_CLOSED',
      message: 'Check-in is not open',
    });
  }
  if (event.checkInSessionId == null) {
    throw new BadRequestException({
      code: 'CHECK_IN_NO_SESSION',
      message: 'No active check-in session',
    });
  }
}

export function assertQrTokenVerifiedForRedeem(
  verified:
    | { ok: true; claims: CheckInQrClaims }
    | { ok: false; reason: VerifyQrFailureReason },
  eventId: string,
  checkInSessionId: string,
): asserts verified is { ok: true; claims: CheckInQrClaims } {
  if (!verified.ok) {
    if (verified.reason === 'EXPIRED') {
      throw new BadRequestException({
        code: 'CHECK_IN_QR_EXPIRED',
        message: 'This QR code has expired',
      });
    }
    throw new BadRequestException({
      code: 'CHECK_IN_INVALID_QR',
      message: 'Invalid QR code',
    });
  }
  if (verified.claims.e !== eventId) {
    throw new BadRequestException({
      code: 'CHECK_IN_WRONG_EVENT',
      message: 'This QR code is for a different event',
    });
  }
  if (verified.claims.s !== checkInSessionId) {
    throw new BadRequestException({
      code: 'CHECK_IN_SESSION_MISMATCH',
      message: 'This QR code is no longer valid',
    });
  }
}
