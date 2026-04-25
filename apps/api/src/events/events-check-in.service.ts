import { Injectable } from '@nestjs/common';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { ManualEventCheckInDto } from './dto/manual-event-check-in.dto';
import type { ListCheckInAttendeesQueryDto } from './dto/list-check-in-attendees-query.dto';
import { EventsCheckInAttendeesService } from './events-check-in-attendees.service';
import { EventsCheckInQrService } from './events-check-in-qr.service';
import { EventsCheckInRedemptionService } from './events-check-in-redemption.service';
import type { RedeemResult, ResolveResult } from './events-check-in.types';

export type { RedeemResult, ResolveResult } from './events-check-in.types';

/**
 * Facade for organizer QR/session, attendee list/mutations, and volunteer redemption flows.
 */
@Injectable()
export class EventsCheckInService {
  constructor(
    private readonly qr: EventsCheckInQrService,
    private readonly attendees: EventsCheckInAttendeesService,
    private readonly redemption: EventsCheckInRedemptionService,
  ) {}

  patchOpen(eventId: string, user: AuthenticatedUser, isOpen: boolean): Promise<void> {
    return this.qr.patchOpen(eventId, user, isOpen);
  }

  rotateSession(eventId: string, user: AuthenticatedUser): Promise<void> {
    return this.qr.rotateSession(eventId, user);
  }

  getQrPayload(
    eventId: string,
    user: AuthenticatedUser,
  ): Promise<{
    qrPayload: string;
    sessionId: string;
    expiresAt: string;
    issuedAtMs: number;
  }> {
    return this.qr.getQrPayload(eventId, user);
  }

  listAttendees(
    eventId: string,
    user: AuthenticatedUser,
    query?: ListCheckInAttendeesQueryDto,
  ): ReturnType<EventsCheckInAttendeesService['listAttendees']> {
    return this.attendees.listAttendees(eventId, user, query);
  }

  manualAdd(
    eventId: string,
    user: AuthenticatedUser,
    dto: ManualEventCheckInDto,
  ): ReturnType<EventsCheckInAttendeesService['manualAdd']> {
    return this.attendees.manualAdd(eventId, user, dto);
  }

  removeAttendee(eventId: string, checkInId: string, user: AuthenticatedUser): Promise<void> {
    return this.attendees.removeAttendee(eventId, checkInId, user);
  }

  redeem(
    eventId: string,
    user: AuthenticatedUser,
    rawPayload: string,
    clientGeo?: { lat: number; lng: number },
  ): Promise<RedeemResult> {
    return this.redemption.redeem(eventId, user, rawPayload, clientGeo);
  }

  resolveCheckIn(
    eventId: string,
    pendingId: string,
    user: AuthenticatedUser,
    action: 'approve' | 'reject',
  ): Promise<ResolveResult | null> {
    return this.redemption.resolveCheckIn(eventId, pendingId, user, action);
  }

  getPendingStatus(
    eventId: string,
    pendingId: string,
    user: AuthenticatedUser,
  ): ReturnType<EventsCheckInRedemptionService['getPendingStatus']> {
    return this.redemption.getPendingStatus(eventId, pendingId, user);
  }
}
