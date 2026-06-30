import { SiteShareAttributionEventDto } from '../dto/site-share-attribution-event.dto';

export function normalizeShareClickEvent(dto: SiteShareAttributionEventDto): SiteShareAttributionEventDto {
  return { ...dto, eventType: 'CLICK', source: 'WEB' };
}

export function normalizeShareOpenEvent(dto: SiteShareAttributionEventDto): SiteShareAttributionEventDto {
  return { ...dto, eventType: 'OPEN', source: 'APP' };
}
