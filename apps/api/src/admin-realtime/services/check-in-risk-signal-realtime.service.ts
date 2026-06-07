import { Injectable } from '@nestjs/common';
import { Subject } from 'rxjs';

export type CheckInRiskSignalSseType =
  | 'check_in_risk_signal_created'
  | 'check_in_risk_signal_updated';

export type CheckInRiskSignalSsePayload = {
  type: CheckInRiskSignalSseType;
  signalId: string;
  eventId?: string;
};

@Injectable()
export class CheckInRiskSignalRealtimeService {
  private readonly events$ = new Subject<CheckInRiskSignalSsePayload>();

  getEvents() {
    return this.events$.asObservable();
  }

  emitCreated(signalId: string, eventId?: string): void {
    this.events$.next({
      type: 'check_in_risk_signal_created',
      signalId,
      ...(eventId ? { eventId } : {}),
    });
  }

  emitUpdated(signalId: string, eventId?: string): void {
    this.events$.next({
      type: 'check_in_risk_signal_updated',
      signalId,
      ...(eventId ? { eventId } : {}),
    });
  }
}
