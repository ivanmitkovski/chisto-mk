import { Injectable } from '@nestjs/common';
import { Subject } from 'rxjs';

export type SiteEventType = 'site_created' | 'site_updated';

export type SiteEvent = {
  type: SiteEventType;
  siteId: string;
};

@Injectable()
export class SiteEventsService {
  private readonly events$ = new Subject<SiteEvent>();

  getEvents() {
    return this.events$.asObservable();
  }

  emitSiteCreated(siteId: string): void {
    this.events$.next({ type: 'site_created', siteId });
  }

  emitSiteUpdated(siteId: string): void {
    this.events$.next({ type: 'site_updated', siteId });
  }
}
