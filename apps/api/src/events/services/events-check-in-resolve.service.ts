import {
  ConflictException,
  GoneException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { Prisma } from '../../prisma-client';
import type { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import {
  POINTS_EVENT_CHECK_IN,
  REASON_EVENT_CHECK_IN,
} from '../../gamification/constants/gamification.constants';
import { EcoEventPointsService } from '../../gamification/services/eco-event-points.service';
import { emitGamificationPointsCredited } from '../../gamification/util/gamification-credit-events.util';
import { CheckInRepository } from '../repositories/check-in.repository';
import { EventCheckInGateway } from '../gateways/event-check-in.gateway';
import { PendingCheckInService } from './pending-check-in.service';
import { CheckInTelemetryService } from './check-in-telemetry.service';
import { EventLiveImpactService } from './event-live-impact.service';
import { EventsCheckInSharedService } from './events-check-in-shared.service';
import type { ResolveResult } from '../types/events-check-in.types';
import { performance } from 'node:perf_hooks';

@Injectable()
export class EventsCheckInResolveService {
  private readonly logger = new Logger(EventsCheckInResolveService.name);

  constructor(
    private readonly checkInRepository: CheckInRepository,
    private readonly shared: EventsCheckInSharedService,
    private readonly ecoEventPoints: EcoEventPointsService,
    private readonly pendingCheckIn: PendingCheckInService,
    private readonly checkInGateway: EventCheckInGateway,
    private readonly checkInTelemetry: CheckInTelemetryService,
    private readonly liveImpact: EventLiveImpactService,
    private readonly eventEmitter: EventEmitter2,
  ) {}

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
      const { checkedInAt, credit } = await this.checkInRepository.prisma.$transaction(async (tx) => {
        const existing = await tx.eventCheckIn.findUnique({
          where: { eventId_dedupeKey: { eventId, dedupeKey } },
        });
        if (existing != null) {
          return {
            checkedInAt: existing.checkedInAt,
            credit: { granted: 0, totalPointsEarnedBefore: 0, totalPointsEarnedAfter: 0 },
          };
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
        const credit = await this.ecoEventPoints.creditIfNew(tx, {
          userId: pending.userId,
          delta: POINTS_EVENT_CHECK_IN,
          reasonCode: REASON_EVENT_CHECK_IN,
          referenceType: 'CleanupEvent',
          referenceId: eventId,
        });
        return { checkedInAt: row.checkedInAt, credit };
      });

      await this.pendingCheckIn.deletePending(pendingId);

      const pointsAwarded = credit.granted;
      if (credit.granted > 0) {
        emitGamificationPointsCredited(this.eventEmitter, pending.userId, credit);
      }

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
      this.eventEmitter.emit('event.check_in', {
        userId: pending.userId,
        metadata: { eventId, pendingId },
      });
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
