import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { Subscription } from 'rxjs';
import { SiteEventsService } from '../../../admin-realtime/services/site-events.service';
import { TypesenseSitesIndexService } from './typesense-sites-index.service';

@Injectable()
export class TypesenseSitesSyncService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(TypesenseSitesSyncService.name);
  private eventSub: Subscription | null = null;
  private readonly debounceTimers = new Map<string, ReturnType<typeof setTimeout>>();
  private static readonly DEBOUNCE_MS = 500;

  constructor(
    private readonly index: TypesenseSitesIndexService,
    private readonly siteEvents: SiteEventsService,
  ) {}

  onModuleInit(): void {
    if (!this.index.isEnabled()) {
      return;
    }
    if (process.env.TYPESENSE_SYNC_ENABLED === 'false') {
      this.logger.log('Typesense incremental sync disabled (TYPESENSE_SYNC_ENABLED=false)');
      return;
    }
    this.eventSub = this.siteEvents.getEvents().subscribe((event) => {
      this.scheduleIndexRefresh(event.siteId);
    });
    this.logger.log('Typesense incremental sync subscribed to site events');
  }

  onModuleDestroy(): void {
    this.eventSub?.unsubscribe();
    this.eventSub = null;
    for (const timer of this.debounceTimers.values()) {
      clearTimeout(timer);
    }
    this.debounceTimers.clear();
  }

  private scheduleIndexRefresh(siteId: string): void {
    const existing = this.debounceTimers.get(siteId);
    if (existing) {
      clearTimeout(existing);
    }
    this.debounceTimers.set(
      siteId,
      setTimeout(() => {
        this.debounceTimers.delete(siteId);
        void this.refreshSite(siteId);
      }, TypesenseSitesSyncService.DEBOUNCE_MS),
    );
  }

  private async refreshSite(siteId: string): Promise<void> {
    try {
      await this.index.upsertSite(siteId);
    } catch (error) {
      this.logger.warn(`Typesense index refresh failed for site ${siteId}: ${String(error)}`);
    }
  }
}
