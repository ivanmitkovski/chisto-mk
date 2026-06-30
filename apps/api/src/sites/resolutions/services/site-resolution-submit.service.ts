import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  AdminModerationCategory,
  AdminNotificationCategory,
  AdminNotificationTone,
  Prisma,
  SiteHistoryEntryKind,
  SiteStatus,
} from '../../../prisma-client';
import { PrismaService } from '../../../prisma/prisma.service';
import type { AuthenticatedUser } from '../../../auth/types/authenticated-user.type';
import { AdminModerationNotifierService } from '../../../admin-moderation-email/services/admin-moderation-notifier.service';
import { resolveActorIdentity } from '../../../common/projections/public-identity.projection';
import { SiteHistoryWriterService } from '../../history/site-history-writer.service';
import { siteVisibilityPrismaWhere } from '../../util/site-visibility.helper';
import { CreateSiteResolutionDto } from '../dto/create-site-resolution.dto';
import { SiteResolutionUploadService } from './site-resolution-upload.service';
import { SiteResolutionQueryService } from './site-resolution-query.service';
import { resolutionSubmitAllowedStatuses } from '../util/transition-site-to-cleaned-on-resolution.helper';
import type { SiteResolutionResponseDto } from '../dto/site-resolution-response.dto';

@Injectable()
export class SiteResolutionSubmitService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly upload: SiteResolutionUploadService,
    private readonly query: SiteResolutionQueryService,
    private readonly siteHistoryWriter: SiteHistoryWriterService,
    private readonly moderationEmailNotifier: AdminModerationNotifierService,
  ) {}

  private async computeIsReporterSubmission(
    tx: Prisma.TransactionClient,
    siteId: string,
    userId: string,
  ): Promise<boolean> {
    const reportLink = await tx.report.findFirst({
      where: {
        siteId,
        OR: [
          { reporterId: userId },
          { coReporters: { some: { userId } } },
        ],
      },
      select: { id: true },
    });
    return reportLink != null;
  }

  async submit(
    siteId: string,
    user: AuthenticatedUser,
    dto: CreateSiteResolutionDto,
  ): Promise<SiteResolutionResponseDto> {
    this.upload.assertMediaUrlsFromOurBucket(dto.mediaUrls);

    const site = await this.prisma.site.findFirst({
      where: {
        id: siteId,
        ...siteVisibilityPrismaWhere(user.userId),
      },
      select: { id: true, status: true, address: true, latitude: true, longitude: true },
    });

    if (!site) {
      throw new NotFoundException({
        code: 'SITE_NOT_FOUND',
        message: `Site with id '${siteId}' was not found`,
      });
    }

    if (site.status === SiteStatus.DISPUTED) {
      throw new BadRequestException({
        code: 'SITE_RESOLUTION_NOT_ALLOWED',
        message: 'Resolution submissions are not allowed for disputed sites.',
      });
    }

    if (site.status === SiteStatus.REPORTED) {
      throw new BadRequestException({
        code: 'SITE_RESOLUTION_NOT_ALLOWED',
        message: 'Resolution submissions are not allowed until the site is verified.',
      });
    }

    if (!resolutionSubmitAllowedStatuses().includes(site.status)) {
      throw new BadRequestException({
        code: 'SITE_RESOLUTION_NOT_ALLOWED',
        message: 'Resolution submissions are not allowed for this site status.',
      });
    }

    const existingPending = await this.prisma.siteResolution.findFirst({
      where: {
        siteId,
        submittedById: user.userId,
        status: 'PENDING',
      },
      select: { id: true },
    });

    if (existingPending) {
      throw new BadRequestException({
        code: 'SITE_RESOLUTION_PENDING_EXISTS',
        message: 'You already have a pending resolution submission for this site.',
      });
    }

    const now = new Date();
    const created = await this.prisma.$transaction(async (tx) => {
      const isReporterSubmission = await this.computeIsReporterSubmission(tx, siteId, user.userId);

      const resolution = await tx.siteResolution.create({
        data: {
          siteId,
          submittedById: user.userId,
          note: dto.note?.trim() || null,
          mediaUrls: dto.mediaUrls,
          isReporterSubmission,
        },
        include: {
          submittedBy: {
            select: { firstName: true, lastName: true, status: true },
          },
        },
      });

      await this.siteHistoryWriter.write(
        {
          siteId,
          kind: SiteHistoryEntryKind.RESOLUTION_SUBMITTED,
          occurredAt: now,
          actor: { userId: user.userId, role: user.role },
          metadata: { resolutionId: resolution.id } as Prisma.InputJsonValue,
        },
        { tx, emitSse: false },
      );

      await tx.adminNotification.create({
        data: {
          title: 'Site cleanup confirmation',
          message: 'A citizen submitted cleanup evidence for review.',
          timeLabel: 'now',
          tone: AdminNotificationTone.info,
          category: AdminNotificationCategory.reports,
          href: `/dashboard/sites/${siteId}`,
          messageTemplateKey: 'site.resolution.submitted',
          messageTemplateParams: { siteId, resolutionId: resolution.id } as Prisma.InputJsonValue,
        },
      });

      return resolution;
    });

    this.siteHistoryWriter.emitHistoryAppended(siteId, created.id);

    const submitterIdentity = resolveActorIdentity(created.submittedBy, {
      actorUserId: created.submittedById,
    });
    this.moderationEmailNotifier.notify({
      category: AdminModerationCategory.SITE_RESOLUTION,
      resourceId: created.id,
      deepLinkPath: `/dashboard/sites/${siteId}`,
      emailContext: {
        address: site.address,
        latitude: site.latitude,
        longitude: site.longitude,
        siteStatus: site.status,
        submitterName: submitterIdentity.displayName ?? '',
        submitterEmail: user.email,
        isReporterSubmission: created.isReporterSubmission,
        photoCount: dto.mediaUrls.length,
        notePreview: dto.note?.trim() ?? null,
        submittedAt: created.createdAt.toISOString(),
      },
    });

    const list = await this.query.listForSite(siteId, user);
    const match = list.data.find((r) => r.id === created.id);
    if (match) {
      return match;
    }

    return {
      id: created.id,
      siteId: created.siteId,
      status: created.status,
      mediaUrls: await this.upload.signUrls(created.mediaUrls),
      note: created.note,
      isReporterSubmission: created.isReporterSubmission,
      createdAt: created.createdAt.toISOString(),
      moderatedAt: null,
      submitter: null,
    };
  }
}
