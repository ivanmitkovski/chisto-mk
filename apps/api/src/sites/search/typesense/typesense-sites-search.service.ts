import { Injectable } from '@nestjs/common';
import { Prisma } from '../../../prisma-client';
import { PrismaService } from '../../../prisma/prisma.service';
import { SiteMapSearchDto } from '../../dto/site-map-search.dto';
import type { RawSearchRow } from '../../types/sites-map-search.types';
import { TypesenseClientService } from './typesense-client.service';
import { buildTypesenseFilterBy, buildTypesenseSortBy } from './typesense-sites-search.filters';

type TypesenseHit = {
  document?: Record<string, unknown>;
  text_match?: number;
};

@Injectable()
export class TypesenseSitesSearchService {
  constructor(
    private readonly typesense: TypesenseClientService,
    private readonly prisma: PrismaService,
  ) {}

  isEnabled(): boolean {
    return this.typesense.isEnabled();
  }

  async search(dto: SiteMapSearchDto, viewerUserId?: string | null): Promise<RawSearchRow[]> {
    const client = this.typesense.getClientOrNull();
    if (!client) {
      throw new Error('Typesense client is not configured');
    }

    const q = dto.query.trim();
    const limit = dto.limit ?? 20;
    const collection = this.typesense.getConfig().collection;
    const filterBy = buildTypesenseFilterBy(dto, viewerUserId);
    const sortBy = buildTypesenseSortBy(dto);

    const searchParams: Record<string, string | number> = {
      q,
      query_by: 'description,address',
      filter_by: filterBy,
      per_page: limit,
    };
    if (sortBy) {
      searchParams.sort_by = sortBy;
    }

    const result = (await client
      .collections(collection)
      .documents()
      .search(searchParams)) as { hits?: TypesenseHit[] };

    const hits = result.hits ?? [];
    if (hits.length === 0) {
      return [];
    }

    const siteIds = hits
      .map((h) => (typeof h.document?.id === 'string' ? h.document.id : null))
      .filter((id): id is string => id != null);

    const mediaBySiteId = await this.loadLatestReportMedia(siteIds);

    return hits.map((hit) => {
      const doc = hit.document ?? {};
      const id = String(doc.id ?? '');
      const score = typeof hit.text_match === 'number' ? hit.text_match : 0;
      const media = mediaBySiteId.get(id) ?? null;
      return {
        id,
        latitude: Number(doc.latitude ?? 0),
        longitude: Number(doc.longitude ?? 0),
        description: typeof doc.description === 'string' ? doc.description : null,
        address: typeof doc.address === 'string' ? doc.address : null,
        status: String(doc.status ?? 'REPORTED') as RawSearchRow['status'],
        score,
        latestReportMediaUrls: media,
      };
    });
  }

  private async loadLatestReportMedia(
    siteIds: string[],
  ): Promise<Map<string, string[] | null>> {
    const out = new Map<string, string[] | null>();
    if (siteIds.length === 0) {
      return out;
    }

    const rows = await this.prisma.$queryRaw<
      Array<{ siteId: string; mediaUrls: string[] | null }>
    >(Prisma.sql`
      SELECT DISTINCT ON (r."siteId")
        r."siteId",
        r."mediaUrls"
      FROM "Report" r
      WHERE r."siteId" IN (${Prisma.join(siteIds)})
      ORDER BY r."siteId", r."createdAt" DESC
    `);

    for (const id of siteIds) {
      out.set(id, null);
    }
    for (const row of rows) {
      const urls = row.mediaUrls ?? [];
      out.set(row.siteId, urls.length > 0 ? urls : null);
    }
    return out;
  }
}
