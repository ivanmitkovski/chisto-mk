import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { PrismaService } from '../prisma/prisma.service';
import { ReportsUploadService } from '../reports/reports-upload.service';
import { ObservabilityStore } from '../observability/observability.store';
import { EcoEventLifecycleStatus } from '../prisma-client';
import { visibilityWhere } from './events-query.include';
import { lifecycleToMobile } from './events-mobile.mapper';
import type {
  EventImpactReceiptEvidenceItemDto,
  EventImpactReceiptResponseDto,
  ImpactReceiptCompleteness,
} from './dto/event-impact-receipt-response.dto';
import { EventsTelemetryService } from './events-telemetry.service';

const MAX_EVIDENCE_ON_RECEIPT = 32;
const MAX_AFTER_IMAGES_ON_RECEIPT = 10;

@Injectable()
export class EventImpactReceiptService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly uploads: ReportsUploadService,
    private readonly eventsTelemetry: EventsTelemetryService,
  ) {}

  /**
   * Impact receipt read model: aggregate counts + signed media. No attendee roster.
   * Refuses UPCOMING and CANCELLED (400 EVENTS_IMPACT_RECEIPT_NOT_AVAILABLE).
   */
  async buildForViewer(eventId: string, user: AuthenticatedUser): Promise<EventImpactReceiptResponseDto> {
    const row = await this.prisma.cleanupEvent.findFirst({
      where: { id: eventId, ...visibilityWhere(user.userId) },
      select: {
        id: true,
        title: true,
        scheduledAt: true,
        endAt: true,
        lifecycleStatus: true,
        participantCount: true,
        checkedInCount: true,
        afterImageKeys: true,
        site: {
          select: {
            address: true,
            description: true,
          },
        },
        organizer: {
          select: { firstName: true, lastName: true },
        },
        liveMetric: {
          select: { reportedBagsCollected: true, updatedAt: true },
        },
        evidencePhotos: {
          orderBy: { createdAt: 'asc' },
          take: MAX_EVIDENCE_ON_RECEIPT,
          select: {
            id: true,
            kind: true,
            objectKey: true,
            caption: true,
            createdAt: true,
          },
        },
        _count: {
          select: { evidencePhotos: true },
        },
      },
    });

    if (row == null) {
      throw new NotFoundException({
        code: 'EVENT_NOT_FOUND',
        message: 'Event not found',
      });
    }

    if (
      row.lifecycleStatus === EcoEventLifecycleStatus.UPCOMING ||
      row.lifecycleStatus === EcoEventLifecycleStatus.CANCELLED
    ) {
      throw new BadRequestException({
        code: 'EVENTS_IMPACT_RECEIPT_NOT_AVAILABLE',
        message: 'Impact receipt is not available for this event state.',
      });
    }

    const siteLabel = this.siteLabel(row.site);
    const organizerName = row.organizer
      ? `${row.organizer.firstName} ${row.organizer.lastName}`.trim()
      : '';

    const afterKeys = row.afterImageKeys.slice(0, MAX_AFTER_IMAGES_ON_RECEIPT);
    const afterSigned = await this.uploads.signUrls(this.uploads.getPublicUrlsForKeys(afterKeys));

    const evidenceSigned = await this.uploads.signUrls(
      this.uploads.getPublicUrlsForKeys(row.evidencePhotos.map((p) => p.objectKey)),
    );
    const evidence: EventImpactReceiptEvidenceItemDto[] = row.evidencePhotos.map((p, i) => ({
      id: p.id,
      kind: p.kind.toLowerCase(),
      imageUrl: evidenceSigned[i] ?? '',
      caption: p.caption,
      createdAt: p.createdAt.toISOString(),
    }));

    const bags = row.liveMetric?.reportedBagsCollected ?? 0;
    const bagsUpdatedAt = row.liveMetric?.updatedAt?.toISOString() ?? null;

    const completeness = this.computeCompleteness(
      row.lifecycleStatus,
      row.afterImageKeys.length,
      row._count.evidencePhotos,
    );

    const asOf = new Date().toISOString();

    const dto: EventImpactReceiptResponseDto = {
      eventId: row.id,
      title: row.title,
      siteLabel,
      scheduledAt: row.scheduledAt.toISOString(),
      endAt: row.endAt?.toISOString() ?? null,
      lifecycleStatus: lifecycleToMobile(row.lifecycleStatus),
      participantCount: row.participantCount,
      checkedInCount: row.checkedInCount,
      reportedBagsCollected: Math.max(0, Math.min(9999, Math.floor(bags))),
      bagsUpdatedAt,
      evidence,
      afterImageUrls: afterSigned,
      completeness,
      asOf,
      organizerName,
    };

    ObservabilityStore.recordImpactReceiptFetch();
    this.eventsTelemetry.emitSpan('events.impact_receipt.fetch', {
      eventId: row.id,
      lifecycle: dto.lifecycleStatus,
      completeness,
    });

    return dto;
  }

  private siteLabel(site: { address: string | null; description: string | null }): string {
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

  private computeCompleteness(
    lifecycle: EcoEventLifecycleStatus,
    afterCount: number,
    evidenceCount: number,
  ): ImpactReceiptCompleteness {
    if (lifecycle === EcoEventLifecycleStatus.IN_PROGRESS) {
      return 'in_progress';
    }
    const hasAfter = afterCount > 0;
    const hasEvidence = evidenceCount > 0;
    if (hasAfter && hasEvidence) {
      return 'full';
    }
    if (!hasAfter && !hasEvidence) {
      return 'partial_missing_after_and_evidence';
    }
    if (!hasAfter) {
      return 'partial_missing_after';
    }
    return 'partial_missing_evidence';
  }
}
