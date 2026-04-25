import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { RouteSegmentStatus } from '../prisma-client';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { PrismaService } from '../prisma/prisma.service';
import { visibilityWhere } from './events-query.include';
import type { EventRouteWaypointDto } from './dto/event-route-waypoint.dto';

const ROUTE_SEGMENTS_LIST_CAP = 500;

@Injectable()
export class EventRouteSegmentsService {
  constructor(private readonly prisma: PrismaService) {}

  async listForEvent(eventId: string, user: AuthenticatedUser) {
    const allowed = await this.prisma.cleanupEvent.findFirst({
      where: { id: eventId, ...visibilityWhere(user.userId) },
      select: { id: true },
    });
    if (allowed == null) {
      throw new NotFoundException({
        code: 'EVENT_NOT_FOUND',
        message: 'Event not found',
      });
    }
    const rows = await this.prisma.eventRouteSegment.findMany({
      where: { eventId },
      orderBy: { sortOrder: 'asc' },
      take: ROUTE_SEGMENTS_LIST_CAP,
      select: {
        id: true,
        sortOrder: true,
        label: true,
        latitude: true,
        longitude: true,
        status: true,
        claimedByUserId: true,
        claimedAt: true,
        completedAt: true,
      },
    });
    return rows.map((r) => ({
      id: r.id,
      sortOrder: r.sortOrder,
      label: r.label,
      latitude: r.latitude,
      longitude: r.longitude,
      status: r.status.toLowerCase(),
      claimedByUserId: r.claimedByUserId,
      claimedAt: r.claimedAt?.toISOString() ?? null,
      completedAt: r.completedAt?.toISOString() ?? null,
    }));
  }

  async replaceWaypoints(
    eventId: string,
    user: AuthenticatedUser,
    waypoints: EventRouteWaypointDto[],
  ) {
    const event = await this.prisma.cleanupEvent.findFirst({
      where: { id: eventId, ...visibilityWhere(user.userId) },
      select: { id: true, organizerId: true },
    });
    if (event == null) {
      throw new NotFoundException({
        code: 'EVENT_NOT_FOUND',
        message: 'Event not found',
      });
    }
    if (event.organizerId !== user.userId) {
      throw new ForbiddenException({
        code: 'NOT_EVENT_ORGANIZER',
        message: 'Only the organizer can edit the route',
      });
    }

    await this.prisma.$transaction(async (tx) => {
      await tx.eventRouteSegment.deleteMany({ where: { eventId } });
      if (waypoints.length > 0) {
        await tx.eventRouteSegment.createMany({
          data: waypoints.map((w, i) => ({
            eventId,
            sortOrder: i,
            label: w.label?.trim() || null,
            latitude: w.latitude,
            longitude: w.longitude,
            status: RouteSegmentStatus.OPEN,
          })),
        });
      }
    });

    return this.listForEvent(eventId, user);
  }

  async claimSegment(segmentId: string, user: AuthenticatedUser) {
    const seg = await this.prisma.eventRouteSegment.findUnique({
      where: { id: segmentId },
      select: {
        id: true,
        eventId: true,
        status: true,
        claimedByUserId: true,
      },
    });
    if (seg == null) {
      throw new NotFoundException({
        code: 'EVENT_NOT_FOUND',
        message: 'Route segment not found',
      });
    }
    await this.assertParticipant(seg.eventId, user.userId);

    if (seg.status === RouteSegmentStatus.COMPLETED) {
      throw new BadRequestException({
        code: 'ROUTE_SEGMENT_NOT_CLAIMABLE',
        message: 'Segment is already completed',
      });
    }
    if (seg.status === RouteSegmentStatus.CLAIMED && seg.claimedByUserId !== user.userId) {
      throw new ConflictException({
        code: 'ROUTE_SEGMENT_CLAIMED',
        message: 'Segment is claimed by another volunteer',
      });
    }
    if (seg.status === RouteSegmentStatus.CLAIMED && seg.claimedByUserId === user.userId) {
      return this.listForEvent(seg.eventId, user);
    }

    const claimedAt = new Date();
    const claimed = await this.prisma.eventRouteSegment.updateMany({
      where: { id: segmentId, status: RouteSegmentStatus.OPEN },
      data: {
        status: RouteSegmentStatus.CLAIMED,
        claimedByUserId: user.userId,
        claimedAt,
      },
    });
    if (claimed.count === 0) {
      const current = await this.prisma.eventRouteSegment.findUnique({
        where: { id: segmentId },
        select: { status: true, claimedByUserId: true },
      });
      if (current?.status === RouteSegmentStatus.CLAIMED && current.claimedByUserId === user.userId) {
        return this.listForEvent(seg.eventId, user);
      }
      throw new ConflictException({
        code: 'ROUTE_SEGMENT_CLAIMED',
        message: 'Segment is claimed by another volunteer',
      });
    }
    return this.listForEvent(seg.eventId, user);
  }

  async completeSegment(segmentId: string, user: AuthenticatedUser) {
    const seg = await this.prisma.eventRouteSegment.findUnique({
      where: { id: segmentId },
      select: {
        id: true,
        eventId: true,
        status: true,
        claimedByUserId: true,
      },
    });
    if (seg == null) {
      throw new NotFoundException({
        code: 'EVENT_NOT_FOUND',
        message: 'Route segment not found',
      });
    }
    const event = await this.prisma.cleanupEvent.findFirst({
      where: { id: seg.eventId, ...visibilityWhere(user.userId) },
      select: { organizerId: true },
    });
    if (event == null) {
      throw new NotFoundException({
        code: 'EVENT_NOT_FOUND',
        message: 'Event not found',
      });
    }
    const isOrganizer = event.organizerId === user.userId;
    if (!isOrganizer) {
      await this.assertParticipant(seg.eventId, user.userId);
    }
    if (seg.status === RouteSegmentStatus.COMPLETED) {
      return this.listForEvent(seg.eventId, user);
    }
    if (seg.status === RouteSegmentStatus.OPEN) {
      if (!isOrganizer) {
        throw new ForbiddenException({
          code: 'ROUTE_SEGMENT_FORBIDDEN',
          message: 'Claim the segment before completing it',
        });
      }
    } else if (seg.status === RouteSegmentStatus.CLAIMED) {
      if (!isOrganizer && seg.claimedByUserId !== user.userId) {
        throw new ForbiddenException({
          code: 'ROUTE_SEGMENT_FORBIDDEN',
          message: 'Only the claimer or organizer can complete this segment',
        });
      }
    } else {
      throw new BadRequestException({
        code: 'ROUTE_SEGMENT_NOT_COMPLETABLE',
        message: 'Segment cannot be completed in its current state',
      });
    }

    await this.prisma.eventRouteSegment.update({
      where: { id: segmentId },
      data: {
        status: RouteSegmentStatus.COMPLETED,
        completedAt: new Date(),
      },
    });
    return this.listForEvent(seg.eventId, user);
  }

  private async assertParticipant(eventId: string, userId: string): Promise<void> {
    const event = await this.prisma.cleanupEvent.findFirst({
      where: { id: eventId, ...visibilityWhere(userId) },
      select: { organizerId: true },
    });
    if (event == null) {
      throw new NotFoundException({
        code: 'EVENT_NOT_FOUND',
        message: 'Event not found',
      });
    }
    if (event.organizerId === userId) {
      return;
    }
    const p = await this.prisma.eventParticipant.findUnique({
      where: { eventId_userId: { eventId, userId } },
      select: { id: true },
    });
    if (p == null) {
      throw new ForbiddenException({
        code: 'CHECK_IN_REQUIRES_JOIN',
        message: 'Join the event before claiming a route segment',
      });
    }
  }
}
