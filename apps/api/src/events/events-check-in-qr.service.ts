import { BadRequestException, Injectable } from '@nestjs/common';
import { CleanupEventStatus, EcoEventLifecycleStatus, Prisma } from '../prisma-client';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { CheckInRepository } from './check-in.repository';
import {
  CHECK_IN_QR_TTL_SEC,
  newCheckInJti,
  signCheckInQrToken,
} from './check-in-qr-token';
import { CheckInTelemetryService } from './check-in-telemetry.service';
import { EventsCheckInSharedService } from './events-check-in-shared.service';
import { performance } from 'node:perf_hooks';

@Injectable()
export class EventsCheckInQrService {
  constructor(
    private readonly checkInRepository: CheckInRepository,
    private readonly shared: EventsCheckInSharedService,
    private readonly checkInTelemetry: CheckInTelemetryService,
  ) {}

  async patchOpen(eventId: string, user: AuthenticatedUser, isOpen: boolean): Promise<void> {
    const row = await this.shared.loadEventForOrganizer(eventId, user);
    if (row.status !== CleanupEventStatus.APPROVED) {
      throw new BadRequestException({
        code: 'EVENT_NOT_APPROVED',
        message: 'Check-in is only available for approved events',
      });
    }
    if (row.lifecycleStatus !== EcoEventLifecycleStatus.IN_PROGRESS) {
      throw new BadRequestException({
        code: 'CHECK_IN_LIFECYCLE',
        message: 'Check-in can only run while the event is in progress',
      });
    }

    const data: Prisma.CleanupEventUpdateInput = { checkInOpen: isOpen };
    if (isOpen && row.checkInSessionId == null) {
      data.checkInSessionId = newCheckInJti();
    }

    await this.checkInRepository.prisma.cleanupEvent.update({
      where: { id: eventId },
      data,
    });
    this.checkInTelemetry.emitAudit('check_in.patch_open', {
      eventId,
      organizerId: user.userId,
      isOpen: isOpen ? 1 : 0,
    });
  }

  async rotateSession(eventId: string, user: AuthenticatedUser): Promise<void> {
    const row = await this.shared.loadEventForOrganizer(eventId, user);
    if (row.status !== CleanupEventStatus.APPROVED) {
      throw new BadRequestException({
        code: 'EVENT_NOT_APPROVED',
        message: 'Check-in is only available for approved events',
      });
    }
    if (row.lifecycleStatus !== EcoEventLifecycleStatus.IN_PROGRESS) {
      throw new BadRequestException({
        code: 'CHECK_IN_LIFECYCLE',
        message: 'Check-in can only run while the event is in progress',
      });
    }
    await this.checkInRepository.prisma.cleanupEvent.update({
      where: { id: eventId },
      data: { checkInSessionId: newCheckInJti() },
    });
    this.checkInTelemetry.emitAudit('check_in.rotate_session', {
      eventId,
      organizerId: user.userId,
    });
  }

  async getQrPayload(
    eventId: string,
    user: AuthenticatedUser,
  ): Promise<{
    qrPayload: string;
    sessionId: string;
    expiresAt: string;
    issuedAtMs: number;
  }> {
    const t0 = performance.now();
    try {
      const row = await this.shared.loadEventForOrganizer(eventId, user);
      if (row.status !== CleanupEventStatus.APPROVED) {
        throw new BadRequestException({
          code: 'EVENT_NOT_APPROVED',
          message: 'Check-in is only available for approved events',
        });
      }
      if (!row.checkInOpen) {
        throw new BadRequestException({
          code: 'CHECK_IN_SESSION_CLOSED',
          message: 'Check-in is not open',
        });
      }
      if (row.checkInSessionId == null || row.checkInSessionId.length === 0) {
        throw new BadRequestException({
          code: 'CHECK_IN_NO_SESSION',
          message: 'No active check-in session',
        });
      }
      if (row.lifecycleStatus !== EcoEventLifecycleStatus.IN_PROGRESS) {
        throw new BadRequestException({
          code: 'CHECK_IN_LIFECYCLE',
          message: 'Check-in can only run while the event is in progress',
        });
      }

      const nowSec = Math.floor(Date.now() / 1000);
      const jti = newCheckInJti();
      const claims = {
        e: eventId,
        s: row.checkInSessionId,
        j: jti,
        iat: nowSec,
        exp: nowSec + CHECK_IN_QR_TTL_SEC,
      };
      const secret = this.shared.getCheckInSecret();
      const qrPayload = signCheckInQrToken(secret, claims);
      const expiresAt = new Date(claims.exp * 1000).toISOString();
      const result = {
        qrPayload,
        sessionId: row.checkInSessionId,
        expiresAt,
        issuedAtMs: claims.iat * 1000,
      };
      this.checkInTelemetry.emitSpan('check_in.get_qr', {
        eventId,
        userId: user.userId,
        durationMs: Math.round(performance.now() - t0),
        outcome: 'success',
      });
      return result;
    } catch (err: unknown) {
      this.checkInTelemetry.emitSpan('check_in.get_qr', {
        eventId,
        userId: user.userId,
        durationMs: Math.round(performance.now() - t0),
        outcome: this.shared.httpExceptionLabel(err),
      });
      throw err;
    }
  }
}
