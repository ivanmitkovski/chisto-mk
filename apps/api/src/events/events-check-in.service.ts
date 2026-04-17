import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  GoneException,
  HttpException,
  Injectable,
  InternalServerErrorException,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
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
import { PrismaService } from '../prisma/prisma.service';
import { ReportsUploadService } from '../reports/reports-upload.service';
import {
  CHECK_IN_QR_TTL_SEC,
  newCheckInJti,
  signCheckInQrToken,
  verifyCheckInQrToken,
} from './check-in-qr-token';
import { ManualEventCheckInDto } from './dto/manual-event-check-in.dto';
import { EventCheckInGateway } from './event-check-in.gateway';
import { PendingCheckInService } from './pending-check-in.service';
import { CheckInTelemetryService } from './check-in-telemetry.service';
import { performance } from 'node:perf_hooks';

export interface RedeemResult {
  status: 'pending_confirmation' | 'already_checked_in';
  pendingId?: string;
  expiresAt?: string;
  checkedInAt?: string;
  pointsAwarded?: number;
}

export interface ResolveResult {
  checkedInAt: string;
  pointsAwarded: number;
  userId: string;
  displayName: string;
}

function visibilityWhere(userId: string): Prisma.CleanupEventWhereInput {
  return {
    OR: [{ status: CleanupEventStatus.APPROVED }, { organizerId: userId }],
  };
}

@Injectable()
export class EventsCheckInService {
  private readonly logger = new Logger(EventsCheckInService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
    private readonly ecoEventPoints: EcoEventPointsService,
    private readonly pendingCheckIn: PendingCheckInService,
    private readonly checkInGateway: EventCheckInGateway,
    private readonly reportsUpload: ReportsUploadService,
    private readonly checkInTelemetry: CheckInTelemetryService,
  ) {}

  private telemetryErrorLabel(err: unknown): string {
    if (err instanceof HttpException) {
      const body = err.getResponse();
      if (typeof body === 'object' && body !== null && 'code' in body) {
        return String((body as { code?: string }).code ?? err.name);
      }
      return err.name;
    }
    return err instanceof Error ? err.name : 'unknown';
  }

  private getCheckInSecret(): Buffer {
    const raw = this.config.get<string>('CHECK_IN_QR_SECRET')?.trim();
    const nodeEnv = this.config.get<string>('NODE_ENV') ?? 'development';
    if (raw != null && raw.length >= 24) {
      return Buffer.from(raw, 'utf8');
    }
    if (nodeEnv === 'production') {
      this.logger.error('CHECK_IN_QR_SECRET missing or too short in production');
      throw new InternalServerErrorException({
        code: 'CHECK_IN_MISCONFIG',
        message: 'Server misconfigured',
      });
    }
    this.logger.warn(
      'CHECK_IN_QR_SECRET not set; using insecure dev default. Set CHECK_IN_QR_SECRET (>= 24 chars) before production.',
    );
    return Buffer.from('dev_only_check_in_qr_secret_min_24', 'utf8');
  }

  private async loadEventForOrganizer(
    eventId: string,
    user: AuthenticatedUser,
  ): Promise<{ id: string; organizerId: string | null; lifecycleStatus: EcoEventLifecycleStatus; status: CleanupEventStatus; checkInSessionId: string | null; checkInOpen: boolean }> {
    const row = await this.prisma.cleanupEvent.findFirst({
      where: { id: eventId, ...visibilityWhere(user.userId) },
      select: {
        id: true,
        organizerId: true,
        lifecycleStatus: true,
        status: true,
        checkInSessionId: true,
        checkInOpen: true,
      },
    });
    if (row == null) {
      throw new NotFoundException({
        code: 'EVENT_NOT_FOUND',
        message: 'Event not found',
      });
    }
    if (row.organizerId !== user.userId) {
      throw new ForbiddenException({
        code: 'NOT_EVENT_ORGANIZER',
        message: 'Only the organizer can manage check-in',
      });
    }
    return row;
  }

  async patchOpen(
    eventId: string,
    user: AuthenticatedUser,
    isOpen: boolean,
  ): Promise<void> {
    const row = await this.loadEventForOrganizer(eventId, user);
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

    await this.prisma.cleanupEvent.update({
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
    const row = await this.loadEventForOrganizer(eventId, user);
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
    await this.prisma.cleanupEvent.update({
      where: { id: eventId },
      data: { checkInSessionId: newCheckInJti() },
    });
    this.checkInTelemetry.emitAudit('check_in.rotate_session', {
      eventId,
      organizerId: user.userId,
    });
  }

  async getQrPayload(eventId: string, user: AuthenticatedUser): Promise<{
    qrPayload: string;
    sessionId: string;
    expiresAt: string;
    issuedAtMs: number;
  }> {
    const t0 = performance.now();
    try {
      const row = await this.loadEventForOrganizer(eventId, user);
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
      const secret = this.getCheckInSecret();
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
        outcome: this.telemetryErrorLabel(err),
      });
      throw err;
    }
  }

  async listAttendees(eventId: string, user: AuthenticatedUser) {
    const t0 = performance.now();
    await this.loadEventForOrganizer(eventId, user);
    const rows = await this.prisma.eventCheckIn.findMany({
      where: { eventId },
      orderBy: { checkedInAt: 'desc' },
      select: {
        id: true,
        dedupeKey: true,
        userId: true,
        guestDisplayName: true,
        checkedInAt: true,
        user: {
          select: { firstName: true, lastName: true, avatarObjectKey: true },
        },
      },
    });
    const data = await Promise.all(
      rows.map(async (r) => {
        const name =
          r.user != null
            ? `${r.user.firstName} ${r.user.lastName}`.trim()
            : (r.guestDisplayName ?? 'Guest');
        const avatarUrl = await this.reportsUpload.signPrivateObjectKey(
          r.user?.avatarObjectKey ?? null,
        );
        return {
          id: r.id,
          dedupeKey: r.dedupeKey,
          userId: r.userId,
          name,
          checkedInAt: r.checkedInAt.toISOString(),
          avatarUrl,
        };
      }),
    );
    this.checkInTelemetry.emitSpan('check_in.list_attendees', {
      eventId,
      userId: user.userId,
      durationMs: Math.round(performance.now() - t0),
      count: data.length,
      outcome: 'success',
    });
    return { data };
  }

  async manualAdd(
    eventId: string,
    user: AuthenticatedUser,
    dto: ManualEventCheckInDto,
  ): Promise<{ id: string; name: string; checkedInAt: string; pointsAwarded: number }> {
    const row = await this.loadEventForOrganizer(eventId, user);
    if (row.lifecycleStatus !== EcoEventLifecycleStatus.IN_PROGRESS) {
      throw new BadRequestException({
        code: 'CHECK_IN_LIFECYCLE',
        message: 'Check-in can only run while the event is in progress',
      });
    }

    const targetUserId = dto.userId.trim();
    const dedupeKey = `u:${targetUserId}`;

    try {
      const created = await this.prisma.$transaction(async (tx) => {
        const participant = await tx.eventParticipant.findUnique({
          where: {
            eventId_userId: { eventId, userId: targetUserId },
          },
        });
        if (participant == null) {
          throw new ForbiddenException({
            code: 'CHECK_IN_REQUIRES_JOIN',
            message: 'Only volunteers who joined the event can be checked in',
          });
        }

        const existing = await tx.eventCheckIn.findUnique({
          where: { eventId_dedupeKey: { eventId, dedupeKey } },
        });
        if (existing != null) {
          throw new ConflictException({
            code: 'CHECK_IN_ALREADY_RECORDED',
            message: 'This volunteer is already checked in',
          });
        }

        const joinedUser = await tx.user.findUnique({
          where: { id: targetUserId },
          select: { firstName: true, lastName: true },
        });
        const displayName =
          joinedUser != null
            ? `${joinedUser.firstName} ${joinedUser.lastName}`.trim()
            : 'Volunteer';

        const checkIn = await tx.eventCheckIn.create({
          data: {
            eventId,
            dedupeKey,
            userId: targetUserId,
          },
        });
        await tx.cleanupEvent.update({
          where: { id: eventId },
          data: { checkedInCount: { increment: 1 } },
        });
        const pointsAwarded = await this.ecoEventPoints.creditIfNew(tx, {
          userId: targetUserId,
          delta: POINTS_EVENT_CHECK_IN,
          reasonCode: REASON_EVENT_CHECK_IN,
          referenceType: 'CleanupEvent',
          referenceId: eventId,
        });
        return { checkIn, displayName, pointsAwarded };
      });
      this.checkInTelemetry.emitAudit('check_in.manual_add', {
        eventId,
        organizerId: user.userId,
        targetUserId,
        pointsAwarded: created.pointsAwarded,
      });
      return {
        id: created.checkIn.id,
        name: created.displayName,
        checkedInAt: created.checkIn.checkedInAt.toISOString(),
        pointsAwarded: created.pointsAwarded,
      };
    } catch (err: unknown) {
      if (
        err instanceof ForbiddenException ||
        err instanceof ConflictException
      ) {
        throw err;
      }
      if (
        err instanceof Prisma.PrismaClientKnownRequestError &&
        err.code === 'P2002'
      ) {
        throw new ConflictException({
          code: 'CHECK_IN_ALREADY_RECORDED',
          message: 'This volunteer is already checked in',
        });
      }
      throw err;
    }
  }

  async removeAttendee(
    eventId: string,
    checkInId: string,
    user: AuthenticatedUser,
  ): Promise<void> {
    await this.loadEventForOrganizer(eventId, user);
    await this.prisma.$transaction(async (tx) => {
      const deleted = await tx.eventCheckIn.deleteMany({
        where: { id: checkInId, eventId },
      });
      if (deleted.count === 0) {
        throw new NotFoundException({
          code: 'CHECK_IN_NOT_FOUND',
          message: 'Check-in record not found',
        });
      }
      await tx.cleanupEvent.update({
        where: { id: eventId },
        data: {
          checkedInCount: { decrement: 1 },
        },
      });
    });
    const ev = await this.prisma.cleanupEvent.findUnique({
      where: { id: eventId },
      select: { checkedInCount: true },
    });
    if (ev != null && ev.checkedInCount < 0) {
      await this.prisma.cleanupEvent.update({
        where: { id: eventId },
        data: { checkedInCount: 0 },
      });
    }
    this.checkInTelemetry.emitAudit('check_in.remove_attendee', {
      eventId,
      organizerId: user.userId,
      checkInId,
    });
  }

  async redeem(
    eventId: string,
    user: AuthenticatedUser,
    rawPayload: string,
  ): Promise<RedeemResult> {
    const t0 = performance.now();
    try {
      const result = await this.doRedeem(eventId, user, rawPayload);
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
        outcome: this.telemetryErrorLabel(err),
      });
      throw err;
    }
  }

  private async doRedeem(
    eventId: string,
    user: AuthenticatedUser,
    rawPayload: string,
  ): Promise<RedeemResult> {
    const event = await this.prisma.cleanupEvent.findFirst({
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

    const participant = await this.prisma.eventParticipant.findUnique({
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
    const secret = this.getCheckInSecret();
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

    const dedupeKey = `u:${user.userId}`;

    // Record JTI immediately (replay protection) and check for existing check-in.
    try {
      await this.prisma.$transaction(async (tx) => {
        try {
          await tx.eventCheckInRedemption.create({
            data: { eventId, jti: claims.j },
          });
        } catch (err: unknown) {
          if (
            err instanceof Prisma.PrismaClientKnownRequestError &&
            err.code === 'P2002'
          ) {
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

    // If user is already checked in, return idempotent success.
    const existing = await this.prisma.eventCheckIn.findUnique({
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

    // Fetch user details for the organizer confirmation modal.
    const userRow = await this.prisma.user.findUnique({
      where: { id: user.userId },
      select: { firstName: true, lastName: true, avatarObjectKey: true },
    });
    const firstName = userRow?.firstName ?? 'Volunteer';
    const lastName = userRow?.lastName ?? '';
    const avatarUrl = await this.reportsUpload.signPrivateObjectKey(
      userRow?.avatarObjectKey,
    );

    // Create pending entry and notify organizer via WebSocket.
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
    await this.loadEventForOrganizer(eventId, user);

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
      const { checkedInAt, pointsAwarded } = await this.prisma.$transaction(async (tx) => {
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
      return result;
    } catch (err: unknown) {
      if (
        err instanceof Prisma.PrismaClientKnownRequestError &&
        err.code === 'P2002'
      ) {
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
        outcome: this.telemetryErrorLabel(err),
      });
      throw err;
    }
  }

  async getPendingStatus(
    eventId: string,
    pendingId: string,
    user: AuthenticatedUser,
  ): Promise<{ status: 'pending'; expiresAt: string } | { status: 'expired' }> {
    const pending = await this.pendingCheckIn.getPending(pendingId);
    if (pending == null) {
      return { status: 'expired' };
    }
    const trimmedEventId = eventId.trim();
    if (pending.eventId !== trimmedEventId || pending.userId !== user.userId) {
      throw new NotFoundException({
        code: 'CHECK_IN_REQUEST_NOT_FOUND',
        message: 'Pending check-in request not found',
      });
    }
    return { status: 'pending', expiresAt: pending.expiresAt };
  }
}
