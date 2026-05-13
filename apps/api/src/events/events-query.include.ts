import type { Prisma } from '../prisma-client';
import { eventDetailIncludeForViewer } from './events-query.include.detail';
import { eventListIncludeForViewer } from './events-query.include.list';
import {
  noCheckInRows,
  noParticipantRows,
  participantDisplayName,
  visibilityWhere,
} from './events-query.include.shared';

export { eventDetailIncludeForViewer, eventListIncludeForViewer };

/** Same graph as list (ranked search reuses list-shaped payloads). */
export const eventSearchIncludeForViewer = eventListIncludeForViewer;
export { noCheckInRows, noParticipantRows, participantDisplayName, visibilityWhere };

/** @deprecated Prefer {@link eventDetailIncludeForViewer} or {@link eventListIncludeForViewer}. */
export const eventIncludeForViewer = eventDetailIncludeForViewer;

export type LoadedEventDetail = Prisma.CleanupEventGetPayload<{
  include: ReturnType<typeof eventDetailIncludeForViewer>;
}>;

export type LoadedEventList = Prisma.CleanupEventGetPayload<{
  include: ReturnType<typeof eventListIncludeForViewer>;
}>;

/** Full detail row (default for services that still use the legacy name). */
export type LoadedEvent = LoadedEventDetail;

/** Union passed to {@link EventsMobileMapperService.toMobileEvent}. */
export type MobileMappableEvent = LoadedEventList | LoadedEventDetail;
