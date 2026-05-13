import {
  ConflictException,
  Injectable,
  Logger,
} from '@nestjs/common';
import { CheckInRiskSignalType, Prisma } from '../prisma-client';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { CheckInRepository } from './check-in.repository';
import { ReportsUploadService } from '../reports/reports-upload.service';
import { verifyCheckInQrToken } from './check-in-qr-token';
import { EventCheckInGateway } from './event-check-in.gateway';
import { PendingCheckInService } from './pending-check-in.service';
import { CheckInTelemetryService } from './check-in-telemetry.service';
import {
  assertQrTokenVerifiedForRedeem,
  assertRedeemEligibleEventAndUser,
} from './check-in-redemption-validator';
import { EventsCheckInSharedService } from './events-check-in-shared.service';
import { visibilityWhere } from './events-query.include.shared';
import type { RedeemResult } from './events-check-in.types';
import { performance } from 'node:perf_hooks';

@Injectable()
export class EventsCheckInRedeemService {
  private readonly logger = new Logger(EventsCheckInRedeemService.name);

  constructor(
    private readonly checkInRepository: CheckInRepository,
    private readonly shared: EventsCheckInSharedService,
    private readonly pendingCheckIn: PendingCheckInService,
    private readonly checkInGateway: EventCheckInGateway,
    private readonly reportsUpload: ReportsUploadService,
    private readonly checkInTelemetry: CheckInTelemetryService,
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
    const participant = await this.checkInRepository.prisma.eventParticipant.findUnique({
      where: {
        eventId_userId: { eventId, userId: user.userId },
      },
    });
    assertRedeemEligibleEventAndUser(event, {
      userId: user.userId,
      isParticipant: participant != null,
    });

    const nowSec = Math.floor(Date.now() / 1000);
    const secret = this.shared.getCheckInSecret();
    const verified = verifyCheckInQrToken(secret, rawPayload.trim(), nowSec);
    if (!verified.ok) {
      this.logger.warn(
        `Redeem rejected: token verification failed (${verified.reason}) for event ${eventId} and user ${user.userId}`,
      );
    }
    assertQrTokenVerifiedForRedeem(verified, eventId, event.checkInSessionId!);
    const { claims } = verified;

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
}
