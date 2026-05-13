import { Injectable } from '@nestjs/common';
import { ReportsUploadService } from '../reports/reports-upload.service';
import { SiteMapSearchDto } from './dto/site-map-search.dto';
import { resolveGeoIntentFromQuery } from './sites-map-search-geo-intent';
import { SitesMapSearchQueryService } from './sites-map-search-query.service';
import type { RawSearchRow, SiteMapSearchItem, SiteMapSearchResponse } from './sites-map-search.types';

export type { GeoIntentBounds, SiteMapSearchItem, SiteMapSearchResponse } from './sites-map-search.types';

@Injectable()
export class SitesSearchService {
  constructor(
    private readonly reportsUpload: ReportsUploadService,
    private readonly mapSearchQuery: SitesMapSearchQueryService,
  ) {}

  async searchMapSites(dto: SiteMapSearchDto): Promise<SiteMapSearchResponse> {
    const q = dto.query.trim();
    if (q.length === 0) {
      return { items: [], suggestions: [], geoIntent: null };
    }

    const geoIntent = resolveGeoIntentFromQuery(q);
    const rows = await this.mapSearchQuery.executeSearch(dto);
    const items = await this.mapRowsToSearchItems(rows);
    const suggestions = this.extractSuggestions(rows);

    return { items, suggestions, geoIntent };
  }

  private async mapRowsToSearchItems(rows: RawSearchRow[]): Promise<SiteMapSearchItem[]> {
    return Promise.all(
      rows.map(async (row) => {
        const { score: _score, latestReportMediaUrls, ...rest } = row;
        const raw = latestReportMediaUrls ?? [];
        const signed = raw.length > 0 ? await this.reportsUpload.signUrls(raw) : [];
        return {
          ...rest,
          ...(signed.length > 0 ? { latestReportMediaUrls: signed } : {}),
        };
      }),
    );
  }

  private extractSuggestions(rows: RawSearchRow[]): string[] {
    const seen = new Set<string>();
    const result: string[] = [];
    for (const row of rows) {
      if (result.length >= 3) break;
      const addr = row.address?.trim();
      if (addr && !seen.has(addr)) {
        seen.add(addr);
        result.push(addr);
      }
    }
    return result;
  }
}
