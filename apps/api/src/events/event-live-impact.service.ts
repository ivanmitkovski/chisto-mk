import {
  ForbiddenException,
  forwardRef,
  Inject,
  Injectable,
  MessageEvent,
  NotFoundException,
} from '@nestjs/common';
import { Observable, concat, from, EMPTY } from 'rxjs';
import { catchError, map, switchMap } from 'rxjs/operators';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { PrismaService } from '../prisma/prisma.service';
import { visibilityWhere } from './events-query.include';
import { EventLiveImpactEventsService } from './event-live-impact-events.service';
import { EventCheckInGateway } from './event-check-in.gateway';
import type { PatchLiveImpactDto } from './dto/patch-live-impact.dto';

const EST_KG_PER_BAG = 3.2;

export interface LiveImpactSnapshotDto {
  eventId: string;
  participantCount: number;
  checkedInCount: number;
  reportedBagsCollected: number;
  estimatedKgCollected: number;
  updatedAt: string;
}

@Injectable()
export class EventLiveImpactService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly bus: EventLiveImpactEventsService,
    @Inject(forwardRef(() => EventCheckInGateway))
    private readonly checkInGateway: EventCheckInGateway,
  ) {}

  async getSnapshot(
    eventId: string,
    user: AuthenticatedUser,
  ): Promise<LiveImpactSnapshotDto> {
    const row = await this.prisma.cleanupEvent.findFirst({
      where: { id: eventId, ...visibilityWhere(user.userId) },
      select: {
        id: true,
        participantCount: true,
        checkedInCount: true,
        updatedAt: true,
        liveMetric: { select: { reportedBagsCollected: true, updatedAt: true } },
      },
    });
    if (row == null) {
      throw new NotFoundException({
        code: 'EVENT_NOT_FOUND',
        message: 'Event not found',
      });
    }
    return this.mapRow(row);
  }

  private mapRow(row: {
    id: string;
    participantCount: number;
    checkedInCount: number;
    updatedAt: Date;
    liveMetric: { reportedBagsCollected: number; updatedAt: Date } | null;
  }): LiveImpactSnapshotDto {
    const bags = row.liveMetric?.reportedBagsCollected ?? 0;
    const metricUpdated = row.liveMetric?.updatedAt ?? row.updatedAt;
    return {
      eventId: row.id,
      participantCount: row.participantCount,
      checkedInCount: row.checkedInCount,
      reportedBagsCollected: bags,
      estimatedKgCollected: Math.round(bags * EST_KG_PER_BAG * 10) / 10,
      updatedAt: metricUpdated.toISOString(),
    };
  }

  async buildSnapshotForRoom(eventId: string): Promise<LiveImpactSnapshotDto | null> {
    const row = await this.prisma.cleanupEvent.findUnique({
      where: { id: eventId },
      select: {
        id: true,
        participantCount: true,
        checkedInCount: true,
        updatedAt: true,
        liveMetric: { select: { reportedBagsCollected: true, updatedAt: true } },
      },
    });
    if (row == null) {
      return null;
    }
    return this.mapRow(row);
  }

  watchLiveImpactSse(
    eventId: string,
    user: AuthenticatedUser,
  ): Observable<MessageEvent> {
    const toEvent = (snap: LiveImpactSnapshotDto): MessageEvent => ({
      data: { type: 'live_impact', payload: snap },
    });
    const initial = from(this.getSnapshot(eventId, user)).pipe(
      map(toEvent),
      catchError(() => EMPTY),
    );
    const updates = this.bus.watchEvent(eventId).pipe(
      switchMap(() =>
        from(this.getSnapshot(eventId, user)).pipe(
          map(toEvent),
          catchError(() => EMPTY),
        ),
      ),
    );
    return concat(initial, updates);
  }

  async patch(
    eventId: string,
    dto: PatchLiveImpactDto,
    user: AuthenticatedUser,
  ): Promise<LiveImpactSnapshotDto> {
    const existing = await this.prisma.cleanupEvent.findFirst({
      where: { id: eventId, ...visibilityWhere(user.userId) },
      select: { id: true, organizerId: true },
    });
    if (existing == null) {
      throw new NotFoundException({
        code: 'EVENT_NOT_FOUND',
        message: 'Event not found',
      });
    }
    if (existing.organizerId !== user.userId) {
      throw new ForbiddenException({
        code: 'NOT_EVENT_ORGANIZER',
        message: 'Only the organizer can update live impact',
      });
    }

    await this.prisma.eventLiveMetric.upsert({
      where: { eventId },
      create: {
        eventId,
        reportedBagsCollected: dto.reportedBagsCollected,
      },
      update: {
        reportedBagsCollected: dto.reportedBagsCollected,
      },
    });

    this.notifyListeners(eventId);
    return this.getSnapshot(eventId, user);
  }

  /** Organizer WebSocket publish — same authorization as PATCH. */
  async publishFromOrganizerSocket(
    eventId: string,
    userId: string,
    reportedBagsCollected: number,
  ): Promise<void> {
    const existing = await this.prisma.cleanupEvent.findFirst({
      where: { id: eventId, ...visibilityWhere(userId) },
      select: { id: true, organizerId: true },
    });
    if (existing == null) {
      return;
    }
    if (existing.organizerId !== userId) {
      return;
    }
    const clamped = Math.max(0, Math.min(9999, Math.floor(reportedBagsCollected)));
    await this.prisma.eventLiveMetric.upsert({
      where: { eventId },
      create: { eventId, reportedBagsCollected: clamped },
      update: { reportedBagsCollected: clamped },
    });
    this.notifyListeners(eventId);
  }

  notifyListeners(eventId: string): void {
    this.bus.emitChanged(eventId);
    void this.buildSnapshotForRoom(eventId)
      .then((snap) => {
        if (snap != null) {
          this.checkInGateway.emitToRoom(eventId, 'live_impact', snap);
        }
      })
      .catch(() => undefined);
  }
}
