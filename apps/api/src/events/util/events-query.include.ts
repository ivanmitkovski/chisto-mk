import type { Prisma } from '../../prisma-client';
import { eventDetailIncludeForViewer } from './events-query.include.detail';
import { eventListIncludeForViewer } from './events-query.include.list';
import {
  noCheckInRows,
  noParticipantRows,
  participantDisplayName,
  visibilityWhere,
} from './events-query.include.shared';

export { eventDetailIncludeForViewer, eventListIncludeForViewer };

export { noCheckInRows, noParticipantRows, participantDisplayName, visibilityWhere };

export type LoadedEventDetail = Prisma.CleanupEventGetPayload<{
  include: ReturnType<typeof eventDetailIncludeForViewer>;
}>;

export type LoadedEventList = Prisma.CleanupEventGetPayload<{
  include: ReturnType<typeof eventListIncludeForViewer>;
}>;

/** Union passed to {@link EventsMobileMapperService.toMobileEvent}. */
export type MobileMappableEvent = LoadedEventList | LoadedEventDetail;
