import { Injectable } from '@nestjs/common';
import { UserStatus } from '../generated/prisma';
import { PrismaService } from '../prisma/prisma.service';

/** Prisma entry point for event check-in persistence (extracted from EventsCheckInService). */
@Injectable()
export class CheckInRepository {
  constructor(public readonly prisma: PrismaService) {}

  /** Load user row for check-in WebSocket handshake (display name + active gate). */
  async findUserForCheckInWebsocket(userId: string): Promise<{
    id: string;
    firstName: string;
    lastName: string;
    status: UserStatus;
  } | null> {
    return this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, firstName: true, lastName: true, status: true },
    });
  }

  /** Organizer or joined participant may subscribe to check-in room fan-out. */
  async isEventParticipantOrOrganizer(userId: string, eventId: string): Promise<boolean> {
    const event = await this.prisma.cleanupEvent.findFirst({
      where: { id: eventId },
      select: { organizerId: true },
    });
    if (event?.organizerId === userId) {
      return true;
    }
    const participant = await this.prisma.eventParticipant.findUnique({
      where: { eventId_userId: { eventId, userId } },
      select: { id: true },
    });
    return participant != null;
  }

  /**
   * Ellipsoidal distance in meters (PostGIS geography + ST_Distance).
   * Prisma cannot express geography distance; raw SQL is required per platform rules.
   */
  async geographyDistanceMeters(
    aLat: number,
    aLng: number,
    bLat: number,
    bLng: number,
  ): Promise<number> {
    const rows = await this.prisma.$queryRaw<Array<{ d: string | number | null }>>`
      SELECT ST_Distance(
        ST_SetSRID(ST_MakePoint(${aLng}, ${aLat}), 4326)::geography,
        ST_SetSRID(ST_MakePoint(${bLng}, ${bLat}), 4326)::geography,
        false
      )::float8 AS d
    `;
    const raw = rows[0]?.d;
    if (raw == null) {
      return 0;
    }
    return typeof raw === 'string' ? Number.parseFloat(raw) : raw;
  }
}
