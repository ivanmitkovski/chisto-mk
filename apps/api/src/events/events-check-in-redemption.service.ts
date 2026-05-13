import { Injectable } from '@nestjs/common';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import type { RedeemResult, ResolveResult } from './events-check-in.types';
import { EventsCheckInRedeemService } from './events-check-in-redeem.service';
import { EventsCheckInResolveService } from './events-check-in-resolve.service';

@Injectable()
export class EventsCheckInRedemptionService {
  constructor(
    private readonly redeemSvc: EventsCheckInRedeemService,
    private readonly resolveSvc: EventsCheckInResolveService,
  ) {}

  redeem(
    eventId: string,
    user: AuthenticatedUser,
    rawPayload: string,
    clientGeo?: { lat: number; lng: number },
  ): Promise<RedeemResult> {
    return this.redeemSvc.redeem(eventId, user, rawPayload, clientGeo);
  }

  resolveCheckIn(
    eventId: string,
    pendingId: string,
    user: AuthenticatedUser,
    action: 'approve' | 'reject',
  ): Promise<ResolveResult | null> {
    return this.resolveSvc.resolveCheckIn(eventId, pendingId, user, action);
  }

  getPendingStatus(
    eventId: string,
    pendingId: string,
    user: AuthenticatedUser,
  ): Promise<{ status: 'pending'; expiresAt: string } | { status: 'expired' }> {
    return this.resolveSvc.getPendingStatus(eventId, pendingId, user);
  }
}
