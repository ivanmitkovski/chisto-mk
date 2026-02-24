import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { Prisma, Site, SiteStatus } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreateSiteDto } from './dto/create-site.dto';
import { ListSitesQueryDto } from './dto/list-sites-query.dto';
import { UpdateSiteStatusDto } from './dto/update-site-status.dto';

type SiteWithReports = Prisma.SiteGetPayload<{
  include: { reports: true };
}>;

const ALLOWED_SITE_STATUS_TRANSITIONS: Record<SiteStatus, SiteStatus[]> = {
  REPORTED: ['VERIFIED', 'DISPUTED'],
  VERIFIED: ['CLEANUP_SCHEDULED', 'DISPUTED'],
  CLEANUP_SCHEDULED: ['IN_PROGRESS', 'DISPUTED'],
  IN_PROGRESS: ['CLEANED', 'DISPUTED'],
  CLEANED: ['DISPUTED'],
  DISPUTED: ['REPORTED', 'VERIFIED'],
};

@Injectable()
export class SitesService {
  constructor(private readonly prisma: PrismaService) {}

  async create(dto: CreateSiteDto): Promise<Site> {
    return this.prisma.site.create({
      data: {
        latitude: dto.latitude,
        longitude: dto.longitude,
        description: dto.description ?? null,
      },
    });
  }

  async findAll(query: ListSitesQueryDto): Promise<{
    data: Site[];
    meta: { page: number; limit: number; total: number };
  }> {
    const where: Prisma.SiteWhereInput = query.status
      ? { status: query.status }
      : {};

    const skip = (query.page - 1) * query.limit;
    const [data, total] = await this.prisma.$transaction([
      this.prisma.site.findMany({
        where,
        skip,
        take: query.limit,
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.site.count({ where }),
    ]);

    return {
      data,
      meta: {
        page: query.page,
        limit: query.limit,
        total,
      },
    };
  }

  async findOne(siteId: string): Promise<SiteWithReports> {
    const site = await this.prisma.site.findUnique({
      where: { id: siteId },
      include: {
        reports: {
          orderBy: { createdAt: 'desc' },
        },
      },
    });

    if (!site) {
      throw new NotFoundException({
        code: 'SITE_NOT_FOUND',
        message: `Site with id '${siteId}' was not found`,
      });
    }

    return site;
  }

  async updateStatus(siteId: string, dto: UpdateSiteStatusDto): Promise<Site> {
    const site = await this.prisma.site.findUnique({
      where: { id: siteId },
      select: { id: true, status: true },
    });

    if (!site) {
      throw new NotFoundException({
        code: 'SITE_NOT_FOUND',
        message: `Site with id '${siteId}' was not found`,
      });
    }

    if (site.status === dto.status) {
      return this.prisma.site.findUniqueOrThrow({
        where: { id: siteId },
      });
    }

    const allowedStatuses = ALLOWED_SITE_STATUS_TRANSITIONS[site.status];
    if (!allowedStatuses.includes(dto.status)) {
      throw new BadRequestException({
        code: 'INVALID_SITE_STATUS_TRANSITION',
        message: `Cannot transition site status from '${site.status}' to '${dto.status}'`,
        details: {
          from: site.status,
          to: dto.status,
          allowedTo: allowedStatuses,
        },
      });
    }

    return this.prisma.site.update({
      where: { id: siteId },
      data: { status: dto.status },
    });
  }
}
