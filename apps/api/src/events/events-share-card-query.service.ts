import { Injectable, NotFoundException } from '@nestjs/common';
import { CleanupEventStatus, EcoEventLifecycleStatus } from '../prisma-client';
import { EventsRepository } from './events.repository';

@Injectable()
export class EventsShareCardQueryService {
  constructor(private readonly eventsRepository: EventsRepository) {}

  /**
   * Minimal fields for HTTPS share landing (`GET /events/:id/share-card`).
   * Approved moderation + non-cancelled lifecycle only (no roster, no organizer PII).
   */
  async findPublicShareCard(id: string) {
    const row = await this.eventsRepository.prisma.cleanupEvent.findFirst({
      where: {
        id,
        status: CleanupEventStatus.APPROVED,
        lifecycleStatus: { not: EcoEventLifecycleStatus.CANCELLED },
      },
      select: {
        id: true,
        title: true,
        scheduledAt: true,
        endAt: true,
        lifecycleStatus: true,
        site: { select: { address: true, description: true } },
      },
    });
    if (row == null) {
      throw new NotFoundException({
        code: 'EVENT_NOT_FOUND',
        message: 'Event not found',
      });
    }
    const siteLabel = this.publicShareSiteLabel(row.site);
    return {
      id: row.id,
      title: row.title,
      siteLabel,
      scheduledAt: row.scheduledAt.toISOString(),
      endAt: row.endAt?.toISOString() ?? null,
      lifecycleStatus: row.lifecycleStatus,
    };
  }

  private publicShareSiteLabel(site: {
    address: string | null;
    description: string | null;
  }): string {
    const a = site.address?.trim();
    if (a != null && a.length > 0) {
      return a;
    }
    const d = site.description?.trim();
    if (d != null && d.length > 0) {
      return d;
    }
    return 'Site';
  }
}
