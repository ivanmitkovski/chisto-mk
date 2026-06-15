import { Injectable } from '@nestjs/common';
import { Prisma, SiteResolutionStatus } from '../../../prisma-client';
import type { AuthenticatedUser } from '../../../auth/types/authenticated-user.type';
import { resolveActorIdentity } from '../../../common/projections/public-identity.projection';
import { PrismaService } from '../../../prisma/prisma.service';
import { SiteResolutionUploadService } from './site-resolution-upload.service';
import type {
  SiteResolutionListResponseDto,
  SiteResolutionResponseDto,
  SiteResolutionSubmitterDto,
} from '../dto/site-resolution-response.dto';
import type { ViewerResolutionStatusMap } from '../util/viewer-resolution-status';

type ResolutionRow = {
  id: string;
  siteId: string;
  status: SiteResolutionStatus;
  mediaUrls: string[];
  note: string | null;
  isReporterSubmission: boolean;
  createdAt: Date;
  moderatedAt: Date | null;
  submittedById: string | null;
  submittedBy: { firstName: string; lastName: string; status: import('../../../prisma-client').UserStatus } | null;
};

@Injectable()
export class SiteResolutionQueryService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly upload: SiteResolutionUploadService,
  ) {}

  private mapSubmitter(
    row: ResolutionRow,
    viewer?: AuthenticatedUser,
  ): SiteResolutionSubmitterDto | null {
    if (row.submittedById == null && row.submittedBy == null) {
      return null;
    }
    const identity = resolveActorIdentity(row.submittedBy, { actorUserId: row.submittedById });
    return {
      displayLabel: identity.displayName,
      isSelf: row.submittedById != null && viewer?.userId === row.submittedById,
      isDeleted: identity.isDeleted,
      isAnonymous: identity.isAnonymous,
    };
  }

  private async mapRow(
    row: ResolutionRow,
    viewer?: AuthenticatedUser,
  ): Promise<SiteResolutionResponseDto> {
    const signed = await this.upload.signUrls(row.mediaUrls);
    return {
      id: row.id,
      siteId: row.siteId,
      status: row.status,
      mediaUrls: signed,
      note: row.note,
      isReporterSubmission: row.isReporterSubmission,
      createdAt: row.createdAt.toISOString(),
      moderatedAt: row.moderatedAt?.toISOString() ?? null,
      submitter: this.mapSubmitter(row, viewer),
    };
  }

  private resolutionInclude = {
    submittedBy: {
      select: { firstName: true, lastName: true, status: true },
    },
  } satisfies Prisma.SiteResolutionInclude;

  async listForSite(
    siteId: string,
    viewer?: AuthenticatedUser,
  ): Promise<SiteResolutionListResponseDto> {
    const where: Prisma.SiteResolutionWhereInput = {
      siteId,
      OR: [
        { status: SiteResolutionStatus.APPROVED },
        ...(viewer?.userId
          ? [{ submittedById: viewer.userId, status: SiteResolutionStatus.PENDING }]
          : []),
      ],
    };

    const rows = await this.prisma.siteResolution.findMany({
      where,
      orderBy: [{ createdAt: 'desc' }],
      include: this.resolutionInclude,
    });

    const data = await Promise.all(rows.map((row) => this.mapRow(row as ResolutionRow, viewer)));
    return { data, meta: { total: data.length } };
  }

  async listForAdmin(query: {
    page: number;
    limit: number;
    status?: SiteResolutionStatus;
    siteId?: string;
  }) {
    const and: Prisma.SiteResolutionWhereInput[] = [];
    if (query.status) {
      and.push({ status: query.status });
    }
    if (query.siteId) {
      and.push({ siteId: query.siteId });
    }
    const where: Prisma.SiteResolutionWhereInput = and.length > 0 ? { AND: and } : {};

    const skip = (query.page - 1) * query.limit;
    const [rows, total] = await this.prisma.$transaction([
      this.prisma.siteResolution.findMany({
        where,
        orderBy: [{ createdAt: 'desc' }],
        skip,
        take: query.limit,
        include: {
          ...this.resolutionInclude,
          site: { select: { address: true, status: true } },
        },
      }),
      this.prisma.siteResolution.count({ where }),
    ]);

    const signedRows = await Promise.all(
      rows.map(async (row) => {
        const signed = await this.upload.signUrls(row.mediaUrls);
        const identity = resolveActorIdentity(row.submittedBy, {
          actorUserId: row.submittedById,
        });
        return {
          id: row.id,
          siteId: row.siteId,
          siteAddress: row.site.address,
          status: row.status,
          mediaUrls: signed,
          note: row.note,
          isReporterSubmission: row.isReporterSubmission,
          createdAt: row.createdAt.toISOString(),
          submitterDisplayLabel: identity.displayName,
          siteStatus: row.site.status,
        };
      }),
    );

    return {
      data: signedRows,
      meta: { page: query.page, limit: query.limit, total },
    };
  }

  /** Batch lookup: APPROVED wins over PENDING for the same site. */
  async getViewerStatusBySiteIds(
    userId: string,
    siteIds: string[],
  ): Promise<ViewerResolutionStatusMap> {
    const unique = [...new Set(siteIds.filter((id) => id.length > 0))];
    if (unique.length === 0) {
      return new Map();
    }
    const rows = await this.prisma.siteResolution.findMany({
      where: {
        submittedById: userId,
        siteId: { in: unique },
        status: { in: [SiteResolutionStatus.PENDING, SiteResolutionStatus.APPROVED] },
      },
      select: { siteId: true, status: true },
    });
    const map: ViewerResolutionStatusMap = new Map();
    for (const row of rows) {
      const existing = map.get(row.siteId);
      if (row.status === SiteResolutionStatus.APPROVED) {
        map.set(row.siteId, 'approved');
      } else if (row.status === SiteResolutionStatus.PENDING && existing !== 'approved') {
        map.set(row.siteId, 'pending');
      }
    }
    return map;
  }
}
