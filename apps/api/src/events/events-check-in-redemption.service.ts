import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  GoneException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import {
  CheckInRiskSignalType,
  CleanupEventStatus,
  EcoEventLifecycleStatus,
  Prisma,
} from '../prisma-client';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import {
  POINTS_EVENT_CHECK_IN,
  REASON_EVENT_CHECK_IN,
} from '../gamification/gamification.constants';
import { EcoEventPointsService } from '../gamification/eco-event-points.service';
import { CheckInRepository } from './check-in.repository';
import { ReportsUploadService } from '../reports/reports-upload.service';
import { verifyCheckInQrToken } from './check-in-qr-token';
import { EventCheckInGateway } from './event-check-in.gateway';
import { PendingCheckInService } from './pending-check-in.service';
import { CheckInTelemetryService } from './check-in-telemetry.service';
import { EventLiveImpactService } from './event-live-impact.service';
import { EventsCheckInSharedService } from './events-check-in-shared.service';
import { visibilityWhere } from './events-query.include';
import type { RedeemResult, ResolveResult } from './events-check-in.types';
import { performance } from 'node:perf_hooks';

@Injectable()
export class EventsCheckInRedemptionService {
  private readonly logger = new Logger(EventsCheckInRedemptionService.name);

  constructor(
    private readonly checkInRepository: CheckInRepository,
    private readonly shared: EventsCheckInSharedService,
    private readonly ecoEventPoints: EcoEventPointsService,
    private readonly pendingCheckIn: PendingCheckInService,
    private readonly checkInGateway: EventCheckInGateway,
    private readonly reportsUpload: ReportsUploadService,
    private readonly checkInTelemetry: CheckInTelemetryService,
    private readonly liveImpact: EventLiveImpactService,
  ) {}

  async redeem(
    eventId: string,
    user: AuthenticatedUser,
    rawPayload: string,
    clientGeo?: { lat: number; lng: number },
  ): Promise<RedeemResult> {
    const t0 = performance.now();
    try {
      const result = await this.doRedeem(eventId, user, rawPayload, clientGeo);
      this.checkInTelemetry.emitMetric({
        op: 'check_in.redeem',
        eventId,
        userId: user.userId,
        durationMs: Math.round(performance.now() - t0),
        outcome: result.status,
      });
      return result;
    } catch (err: unknown) {
      this.checkInTelemetry.emitMetric({
        op: 'check_in.redeem',
        eventId,
        userId: user.userId,
        durationMs: Math.round(performance.now() - t0),
        outcome: this.shared.httpExceptionLabel(err),
      });
      throw err;
    }
  }

  private async maybeRecordFarFromSiteRisk(
    eventId: string,
    userId: string,
    clientGeo?: { lat: number; lng: number },
  ): Promise<void> {
    if (clientGeo == null) {
      return;
    }
    const row = await this.checkInRepository.prisma.cleanupEvent.findUnique({
      where: { id: eventId },
      select: {
        site: { select: { latitude: true, longitude: true } },
      },
    });
    if (row?.site == null) {
      return;
    }
    const meters = await this.checkInRepository.geographyDistanceMeters(
      clientGeo.lat,
      clientGeo.lng,
      row.site.latitude,
      row.site.longitude,
    );
    const thresholdM = 250;
    if (meters <= thresholdM) {
      return;
    }
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 90);
    await this.checkInRepository.prisma.checkInRiskSignal.create({
      data: {
        eventId,
        userId,
        signalType: CheckInRiskSignalType.FAR_FROM_SITE,
        expiresAt,
        metadata: {
          distanceMeters: Math.round(meters),
          thresholdMeters: thresholdM,
        },
      },
    });
  }

  private async doRedeem(
    eventId: string,
    user: AuthenticatedUser,
    rawPayload: string,
    clientGeo?: { lat: number; lng: number },
  ): Promise<RedeemResult> {
    const event = await this.checkInRepository.prisma.cleanupEvent.findFirst({
      where: { id: eventId, ...visibilityWhere(user.userId) },
      select: {
        id: true,
        organizerId: true,
        status: true,
        lifecycleStatus: true,
        checkInSessionId: true,
        checkInOpen: true,
      },
    });
    if (event == null) {
      throw new NotFoundException({
        code: 'EVENT_NOT_FOUND',
        message: 'Event not found',
      });
    }
    if (event.organizerId === user.userId) {
      throw new ForbiddenException({
        code: 'ORGANIZER_CANNOT_CHECK_IN',
        message: 'Organizers use the organizer check-in tools',
      });
    }

    const participant = await this.checkInRepository.prisma.eventParticipant.findUnique({
      where: {
        eventId_userId: { eventId, userId: user.userId },
      },
    });
    if (participant == null) {
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

    const nowSec = Math.floor(Date.now() / 1000);
    const secret = this.shared.getCheckInSecret();
    const verified = verifyCheckInQrToken(secret, rawPayload.trim(), nowSec);
    if (!verified.ok) {
      this.logger.warn(
        `Redeem rejected: token verification failed (${verified.reason}) for event ${eventId} and user ${user.userId}`,
      );
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
    const { claims } = verified;
    if (claims.e !== eventId) {
      this.logger.warn(
        `Redeem rejected: wrong event claim (${claims.e}) for event ${eventId} and user ${user.userId}`,
      );
      throw new BadRequestException({
        code: 'CHECK_IN_WRONG_EVENT',
        message: 'This QR code is for a different event',
      });
    }
    if (claims.s !== event.checkInSessionId) {
      this.logger.warn(
        `Redeem rejected: session mismatch for event ${eventId} and user ${user.userId}`,
      );
      throw new BadRequestException({
        code: 'CHECK_IN_SESSION_MISMATCH',
        message: 'This QR code is no longer valid',
      });
    }

    await this.maybeRecordFarFromSiteRisk(eventId, user.userId, clientGeo);

    const dedupeKey = `u:${user.userId}`;

    try {
      await this.checkInRepository.prisma.$transaction(async (tx) => {
        try {
          await tx.eventCheckInRedemption.create({
            data: { eventId, jti: claims.j },
          });
        } catch (err: unknown) {
          if (err instanceof Prisma.PrismaClientKnownRequestError && err.code === 'P2002') {
            throw new ConflictException({
              code: 'CHECK_IN_REPLAY',
              message: 'This QR code was already used',
            });
          }
          throw err;
        }
      });
    } catch (err: unknown) {
      if (err instanceof ConflictException) {
        this.logger.warn(
          `Redeem conflict for event ${eventId} and user ${user.userId}: ${JSON.stringify(err.getResponse())}`,
        );
        throw err;
      }
      throw err;
    }

    const existing = await this.checkInRepository.prisma.eventCheckIn.findUnique({
      where: { eventId_dedupeKey: { eventId, dedupeKey } },
      select: { checkedInAt: true },
    });
    if (existing != null) {
      return {
        status: 'already_checked_in',
        checkedInAt: existing.checkedInAt.toISOString(),
        pointsAwarded: 0,
      };
    }

    const userRow = await this.checkInRepository.prisma.user.findUnique({
      where: { id: user.userId },
      select: { firstName: true, lastName: true, avatarObjectKey: true },
    });
    const firstName = userRow?.firstName ?? 'Volunteer';
    const lastName = userRow?.lastName ?? '';
    const avatarUrl = await this.reportsUpload.signPrivateObjectKey(userRow?.avatarObjectKey);

    const pending = await this.pendingCheckIn.createPending(
      eventId,
      user.userId,
      firstName,
      lastName,
      avatarUrl,
    );

    try {
      this.checkInGateway.emitToRoom(eventId, 'checkin:request', {
        pendingId: pending.pendingId,
        eventId,
        userId: user.userId,
        firstName,
        lastName,
        avatarUrl,
        expiresAt: pending.expiresAt,
      });
    } catch (err: unknown) {
      this.logger.warn(`Failed to emit checkin:request via WS: ${String(err)}`);
    }

    return {
      status: 'pending_confirmation',
      pendingId: pending.pendingId,
      expiresAt: pending.expiresAt,
    };
  }

  async resolveCheckIn(
    eventId: string,
    pendingId: string,
    user: AuthenticatedUser,
    action: 'approve' | 'reject',
  ): Promise<ResolveResult | null> {
    const t0 = performance.now();
    await this.shared.loadEventForOrganizer(eventId, user);

    const pending = await this.pendingCheckIn.getPending(pendingId);
    if (pending == null) {
      throw new GoneException({
        code: 'CHECK_IN_REQUEST_EXPIRED',
        message: 'This check-in request has expired',
      });
    }
    if (pending.eventId !== eventId) {
      throw new NotFoundException({
        code: 'CHECK_IN_REQUEST_NOT_FOUND',
        message: 'Pending check-in not found for this event',
      });
    }

    if (action === 'reject') {
      await this.pendingCheckIn.deletePending(pendingId);
      try {
        this.checkInGateway.emitToRoom(eventId, 'checkin:rejected', {
          pendingId,
          eventId,
          userId: pending.userId,
        });
      } catch (err: unknown) {
        this.logger.warn(`Failed to emit checkin:rejected via WS: ${String(err)}`);
      }
      this.checkInTelemetry.emitAudit('check_in.resolve', {
        eventId,
        organizerId: user.userId,
        pendingId,
        action: 'reject',
        volunteerUserId: pending.userId,
      });
      this.checkInTelemetry.emitSpan('check_in.resolve', {
        eventId,
        userId: user.userId,
        durationMs: Math.round(performance.now() - t0),
        outcome: 'reject',
      });
      return null;
    }

    const dedupeKey = `u:${pending.userId}`;
    const displayName = `${pending.firstName} ${pending.lastName}`.trim() || 'Volunteer';

    try {
      const { checkedInAt, pointsAwarded } = await this.checkInRepository.prisma.$transaction(async (tx) => {
        const existing = await tx.eventCheckIn.findUnique({
          where: { eventId_dedupeKey: { eventId, dedupeKey } },
        });
        if (existing != null) {
          return { checkedInAt: existing.checkedInAt, pointsAwarded: 0 };
        }

        const row = await tx.eventCheckIn.create({
          data: {
            eventId,
            dedupeKey,
            userId: pending.userId,
          },
        });
        await tx.cleanupEvent.update({
          where: { id: eventId },
          data: { checkedInCount: { increment: 1 } },
        });
        const points = await this.ecoEventPoints.creditIfNew(tx, {
          userId: pending.userId,
          delta: POINTS_EVENT_CHECK_IN,
          reasonCode: REASON_EVENT_CHECK_IN,
          referenceType: 'CleanupEvent',
          referenceId: eventId,
        });
        return { checkedInAt: row.checkedInAt, pointsAwarded: points };
      });

      await this.pendingCheckIn.deletePending(pendingId);

      const result: ResolveResult = {
        checkedInAt: checkedInAt.toISOString(),
        pointsAwarded,
        userId: pending.userId,
        displayName,
      };

      try {
        this.checkInGateway.emitToRoom(eventId, 'checkin:confirmed', {
          pendingId,
          eventId,
          userId: pending.userId,
          checkedInAt: result.checkedInAt,
          pointsAwarded: result.pointsAwarded,
          displayName,
        });
      } catch (err: unknown) {
        this.logger.warn(`Failed to emit checkin:confirmed via WS: ${String(err)}`);
      }

      this.checkInTelemetry.emitAudit('check_in.resolve', {
        eventId,
        organizerId: user.userId,
        pendingId,
        action: 'approve',
        volunteerUserId: pending.userId,
        pointsAwarded: result.pointsAwarded,
      });
      this.checkInTelemetry.emitSpan('check_in.resolve', {
        eventId,
        userId: user.userId,
        durationMs: Math.round(performance.now() - t0),
        outcome: 'approve',
      });
      this.liveImpact.notifyListeners(eventId);
      return result;
    } catch (err: unknown) {
      if (err instanceof Prisma.PrismaClientKnownRequestError && err.code === 'P2002') {
        await this.pendingCheckIn.deletePending(pendingId);
        this.checkInTelemetry.emitSpan('check_in.resolve', {
          eventId,
          userId: user.userId,
          durationMs: Math.round(performance.now() - t0),
          outcome: 'CHECK_IN_ALREADY_CHECKED_IN',
        });
        throw new ConflictException({
          code: 'CHECK_IN_ALREADY_CHECKED_IN',
          message: 'This volunteer is already checked in',
        });
      }
      this.checkInTelemetry.emitSpan('check_in.resolve', {
        eventId,
        userId: user.userId,
        durationMs: Math.round(performance.now() - t0),
        outcome: this.shared.httpExceptionLabel(err),
      });
      throw err;
    }
  }

  async getPendingStatus(
    eventId: string,
    pendingId: string,
    user: AuthenticatedUser,
  ): Promise<{ status: 'pending'; expiresAt: string } | { status: 'expired' }> {
    const p = await this.pendingCheckIn.getPending(pendingId);
    if (p == null) {
      return { status: 'expired' };
    }
    const trimmedEventId = eventId.trim();
    if (p.eventId !== trimmedEventId || p.userId !== user.userId) {
      throw new NotFoundException({
        code: 'CHECK_IN_REQUEST_NOT_FOUND',
        message: 'Pending check-in request not found',
      });
    }
    return { status: 'pending', expiresAt: p.expiresAt };
  }
}
