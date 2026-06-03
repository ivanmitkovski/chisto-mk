import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';
import { TypesenseClientService } from './typesense-client.service';
import {
  TYPESENSE_SITES_COLLECTION_FIELDS,
  type TypesenseSiteDocument,
} from './typesense-sites-collection';

@Injectable()
export class TypesenseSitesIndexService {
  private readonly logger = new Logger(TypesenseSitesIndexService.name);
  private collectionReady = false;

  constructor(
    private readonly typesense: TypesenseClientService,
    private readonly prisma: PrismaService,
  ) {}

  isEnabled(): boolean {
    return this.typesense.isEnabled();
  }

  async ensureCollection(): Promise<void> {
    if (!this.typesense.isEnabled() || this.collectionReady) {
      return;
    }
    const client = this.typesense.getClientOrNull();
    if (!client) return;
    const name = this.typesense.getConfig().collection;
    try {
      await client.collections(name).retrieve();
      this.collectionReady = true;
      return;
    } catch {
      // create below
    }
    await client.collections().create({
      name,
      fields: TYPESENSE_SITES_COLLECTION_FIELDS,
      default_sorting_field: 'updatedAt',
    });
    this.collectionReady = true;
    this.logger.log(`Created Typesense collection "${name}"`);
  }

  async upsertSite(siteId: string): Promise<void> {
    if (!this.typesense.isEnabled()) return;
    const doc = await this.buildDocument(siteId);
    const client = this.typesense.getClientOrNull();
    if (!client) return;
    await this.ensureCollection();
    const collection = this.typesense.getConfig().collection;
    if (!doc) {
      try {
        await client.collections(collection).documents(siteId).delete();
      } catch {
        // idempotent delete
      }
      return;
    }
    await client.collections(collection).documents().upsert(doc);
  }

  async deleteSite(siteId: string): Promise<void> {
    if (!this.typesense.isEnabled()) return;
    const client = this.typesense.getClientOrNull();
    if (!client) return;
    const collection = this.typesense.getConfig().collection;
    try {
      await client.collections(collection).documents(siteId).delete();
    } catch {
      // idempotent
    }
  }

  async buildDocument(siteId: string): Promise<TypesenseSiteDocument | null> {
    const site = await this.prisma.site.findUnique({
      where: { id: siteId },
      select: {
        id: true,
        latitude: true,
        longitude: true,
        description: true,
        address: true,
        status: true,
        isArchivedByAdmin: true,
        updatedAt: true,
        reports: {
          select: {
            category: true,
            reporterId: true,
            coReporters: { select: { userId: true } },
          },
        },
      },
    });
    if (!site) return null;

    const pollutionCategories = [
      ...new Set(
        site.reports
          .map((r) => r.category?.trim())
          .filter((c): c is string => Boolean(c && c.length > 0)),
      ),
    ];
    const reporterUserIds = [
      ...new Set(
        site.reports.flatMap((r) => [
          r.reporterId,
          ...r.coReporters.map((c) => c.userId),
        ]),
      ),
    ].filter((id): id is string => typeof id === 'string' && id.length > 0);

    const doc: TypesenseSiteDocument = {
      id: site.id,
      latitude: site.latitude,
      longitude: site.longitude,
      status: site.status,
      isArchivedByAdmin: site.isArchivedByAdmin,
      updatedAt: Math.floor(site.updatedAt.getTime() / 1000),
      location: [site.latitude, site.longitude],
    };
    if (site.description) {
      doc.description = site.description;
    }
    if (site.address) {
      doc.address = site.address;
    }
    if (pollutionCategories.length > 0) {
      doc.pollutionCategories = pollutionCategories;
    }
    if (reporterUserIds.length > 0) {
      doc.reporterUserIds = reporterUserIds;
    }
    return doc;
  }
}
