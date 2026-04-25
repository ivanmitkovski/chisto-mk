import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { EcoEventLifecycleStatus, Prisma } from '../prisma-client';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import {
  POINTS_EVENT_CHECK_IN,
  REASON_EVENT_CHECK_IN,
  REASON_EVENT_CHECK_IN_REMOVED,
} from '../gamification/gamification.constants';
import { EcoEventPointsService } from '../gamification/eco-event-points.service';
import { CheckInRepository } from './check-in.repository';
import { ReportsUploadService } from '../reports/reports-upload.service';
import { decodeCheckInAttendeesCursor, encodeCheckInAttendeesCursor } from './check-in-attendees-cursor.util';
import { ManualEventCheckInDto } from './dto/manual-event-check-in.dto';
import type { ListCheckInAttendeesQueryDto } from './dto/list-check-in-attendees-query.dto';
import { CheckInTelemetryService } from './check-in-telemetry.service';
import { EventLiveImpactService } from './event-live-impact.service';
import { EventsCheckInSharedService } from './events-check-in-shared.service';
import { performance } from 'node:perf_hooks';

@Injectable()
export class EventsCheckInAttendeesService {
  constructor(
    private readonly checkInRepository: CheckInRepository,
    private readonly shared: EventsCheckInSharedService,
    private readonly ecoEventPoints: EcoEventPointsService,
    private readonly reportsUpload: ReportsUploadService,
    private readonly checkInTelemetry: CheckInTelemetryService,
    private readonly liveImpact: EventLiveImpactService,
  ) {}

  async listAttendees(
    eventId: string,
    user: AuthenticatedUser,
    query?: ListCheckInAttendeesQueryDto,
  ): Promise<{
    data: Array<{
      id: string;
      dedupeKey: string;
      userId: string | null;
      name: string;
      checkedInAt: string;
      avatarUrl: string | null;
    }>;
    meta: { hasMore: boolean; nextCursor: string | null };
  }> {
    const t0 = performance.now();
    await this.shared.loadEventForOrganizer(eventId, user);
    const rawLimit = query?.limit ?? 50;
    const limit = Math.min(50, Math.max(1, rawLimit));
    const cursorRaw = query?.cursor?.trim();
    const cursor =
      cursorRaw != null && cursorRaw.length > 0 ? decodeCheckInAttendeesCursor(cursorRaw) : null;
    if (cursorRaw != null && cursorRaw.length > 0 && cursor == null) {
      throw new BadRequestException({
        code: 'CHECK_IN_ATTENDEES_CURSOR_INVALID',
        message: 'Invalid attendees list cursor',
      });
    }
    const take = limit + 1;
    const rows = await this.checkInRepository.prisma.eventCheckIn.findMany({
      where: {
        eventId,
        ...(cursor != null
          ? {
              OR: [
                { checkedInAt: { lt: cursor.checkedInAt } },
                {
                  AND: [{ checkedInAt: cursor.checkedInAt }, { id: { lt: cursor.id } }],
                },
              ],
            }
          : {}),
      },
      orderBy: [{ checkedInAt: 'desc' }, { id: 'desc' }],
      take,
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
    const hasMore = rows.length > limit;
    const pageRows = hasMore ? rows.slice(0, limit) : rows;
    const avatarKeys = new Set<string>();
    for (const r of pageRows) {
      if (r.user?.avatarObjectKey) {
        avatarKeys.add(r.user.avatarObjectKey);
      }
    }
    const avatarUrlByKey = new Map<string, string | null>();
    await Promise.all(
      [...avatarKeys].map(async (key) => {
        avatarUrlByKey.set(key, await this.reportsUpload.signPrivateObjectKey(key));
      }),
    );
    const data = pageRows.map((r) => {
      const name =
        r.user != null
          ? `${r.user.firstName} ${r.user.lastName}`.trim()
          : (r.guestDisplayName ?? 'Guest');
      const key = r.user?.avatarObjectKey ?? null;
      const avatarUrl = key != null ? (avatarUrlByKey.get(key) ?? null) : null;
      return {
        id: r.id,
        dedupeKey: r.dedupeKey,
        userId: r.userId,
        name,
        checkedInAt: r.checkedInAt.toISOString(),
        avatarUrl,
      };
    });
    const last = pageRows[pageRows.length - 1];
    const nextCursor =
      hasMore && last != null ? encodeCheckInAttendeesCursor(last.checkedInAt, last.id) : null;
    this.checkInTelemetry.emitSpan('check_in.list_attendees', {
      eventId,
      userId: user.userId,
      durationMs: Math.round(performance.now() - t0),
      count: data.length,
      outcome: 'success',
    });
    return { data, meta: { hasMore, nextCursor } };
  }

  async manualAdd(
    eventId: string,
    user: AuthenticatedUser,
    dto: ManualEventCheckInDto,
  ): Promise<{ id: string; name: string; checkedInAt: string; pointsAwarded: number }> {
    const row = await this.shared.loadEventForOrganizer(eventId, user);
    if (row.lifecycleStatus !== EcoEventLifecycleStatus.IN_PROGRESS) {
      throw new BadRequestException({
        code: 'CHECK_IN_LIFECYCLE',
        message: 'Check-in can only run while the event is in progress',
      });
    }

    const targetUserId = dto.userId.trim();
    const dedupeKey = `u:${targetUserId}`;

    try {
      const created = await this.checkInRepository.prisma.$transaction(async (tx) => {
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
      this.liveImpact.notifyListeners(eventId);
      return {
        id: created.checkIn.id,
        name: created.displayName,
        checkedInAt: created.checkIn.checkedInAt.toISOString(),
        pointsAwarded: created.pointsAwarded,
      };
    } catch (err: unknown) {
      if (err instanceof ForbiddenException || err instanceof ConflictException) {
        throw err;
      }
      if (err instanceof Prisma.PrismaClientKnownRequestError && err.code === 'P2002') {
        throw new ConflictException({
          code: 'CHECK_IN_ALREADY_RECORDED',
          message: 'This volunteer is already checked in',
        });
      }
      throw err;
    }
  }

  async removeAttendee(eventId: string, checkInId: string, user: AuthenticatedUser): Promise<void> {
    await this.shared.loadEventForOrganizer(eventId, user);
    await this.checkInRepository.prisma.$transaction(async (tx) => {
      const cin = await tx.eventCheckIn.findFirst({
        where: { id: checkInId, eventId },
        select: { userId: true },
      });
      if (cin == null) {
        throw new NotFoundException({
          code: 'CHECK_IN_NOT_FOUND',
          message: 'Check-in record not found',
        });
      }
      await tx.eventCheckIn.deleteMany({
        where: { id: checkInId, eventId },
      });
      await tx.cleanupEvent.update({
        where: { id: eventId },
        data: {
          checkedInCount: { decrement: 1 },
        },
      });
      if (cin.userId != null) {
        await this.ecoEventPoints.debitOnceIfNew(tx, {
          userId: cin.userId,
          delta: -POINTS_EVENT_CHECK_IN,
          reasonCode: REASON_EVENT_CHECK_IN_REMOVED,
          referenceType: 'CleanupEvent',
          referenceId: `checkInRemoved:${eventId}:${checkInId}`,
          onlyIfPositiveGrant: {
            reasonCode: REASON_EVENT_CHECK_IN,
            referenceType: 'CleanupEvent',
            referenceId: eventId,
          },
        });
      }
    });
    const ev = await this.checkInRepository.prisma.cleanupEvent.findUnique({
      where: { id: eventId },
      select: { checkedInCount: true },
    });
    if (ev != null && ev.checkedInCount < 0) {
      await this.checkInRepository.prisma.cleanupEvent.update({
        where: { id: eventId },
        data: { checkedInCount: 0 },
      });
    }
    this.checkInTelemetry.emitAudit('check_in.remove_attendee', {
      eventId,
      organizerId: user.userId,
      checkInId,
    });
    this.liveImpact.notifyListeners(eventId);
  }
}
