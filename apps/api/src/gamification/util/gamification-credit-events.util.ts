import { EventEmitter2 } from '@nestjs/event-emitter';
import type { EcoEventPointsCreditResult } from '../services/eco-event-points.service';

export const GAMIFICATION_POINTS_CREDITED_EVENT = 'gamification.points.credited';

export type GamificationPointsCreditedPayload = {
  userId: string;
  credit: EcoEventPointsCreditResult;
};

export function emitGamificationPointsCredited(
  eventEmitter: EventEmitter2,
  userId: string,
  credit: EcoEventPointsCreditResult,
): void {
  if (credit.granted <= 0) {
    return;
  }
  eventEmitter.emit(GAMIFICATION_POINTS_CREDITED_EVENT, {
    userId,
    credit,
  } satisfies GamificationPointsCreditedPayload);
}
