import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { S3StorageClient } from '../storage/s3-storage.client';
import { ReportsUploadService } from './reports-upload.service';

/** Objects must be this old before GC (upload-then-never-submit window). */
const MIN_AGE_MS = 72 * 60 * 60 * 1000;
const LIST_PAGE_SIZE = 250;
const MAX_DELETES_PER_RUN = 80;
const REFERENCE_BATCH_SIZE = 80;
const RUN_INTERVAL_MS = 86_400_000;

const REPORT_MEDIA_KEY_RE = /^reports\/[^/]+\/[^/]+\.(jpe?g|png|webp)$/i;

function collectReferencedKeys(
  batch: ReadonlyArray<{ key: string; canonicalUrl: string }>,
  rows: ReadonlyArray<{ mediaUrls: string[] }>,
): Set<string> {
  const referenced = new Set<string>();
  for (const row of rows) {
    for (const url of row.mediaUrls) {
      for (const { key, canonicalUrl } of batch) {
        if (url === canonicalUrl || url === key || url.includes(key)) {
          referenced.add(key);
        }
      }
    }
  }
  return referenced;
}

/**
 * Best-effort deletion of report upload prefix objects that are no longer referenced on any
 * `Report.mediaUrls` row. Mitigates S3 orphans when clients upload then abandon submit.
 *
 * Uses the same interval pattern as {@link ReportSubmitIdempotencyCleanupService} (no extra deps).
 */
@Injectable()
export class ReportUploadOrphanGcService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(ReportUploadOrphanGcService.name);
  private interval?: NodeJS.Timeout;

  constructor(
    private readonly prisma: PrismaService,
    private readonly s3: S3StorageClient,
    private readonly reportsUpload: ReportsUploadService,
  ) {}

  onModuleInit(): void {
    void this.runOnce().catch((err: unknown) => {
      this.logger.warn(`initial report upload orphan GC failed: ${String(err)}`);
    });
    this.interval = setInterval(() => {
      void this.runOnce().catch((err: unknown) => {
        this.logger.warn(`report upload orphan GC failed: ${String(err)}`);
      });
    }, RUN_INTERVAL_MS);
  }

  onModuleDestroy(): void {
    if (this.interval) {
      clearInterval(this.interval);
    }
  }

  async runOnce(): Promise<void> {
    if (!this.s3.enabled) {
      return;
    }
    const base = this.s3.getVirtualHostedHttpsBase();
    if (!base) {
      return;
    }

    const now = Date.now();
    let deleted = 0;
    let continuationToken: string | undefined;

    outer: do {
      const page = await this.s3.listObjectsByPrefix(
        continuationToken
          ? {
              prefix: 'reports/',
              maxKeys: LIST_PAGE_SIZE,
              continuationToken,
            }
          : {
              prefix: 'reports/',
              maxKeys: LIST_PAGE_SIZE,
            },
      );
      continuationToken = page.continuationToken;

      const batch: Array<{ key: string; canonicalUrl: string; lastModified: Date }> = [];
      for (const { key, lastModified } of page.objects) {
        if (deleted >= MAX_DELETES_PER_RUN) {
          break outer;
        }
        if (!REPORT_MEDIA_KEY_RE.test(key)) {
          continue;
        }
        if (!lastModified || now - lastModified.getTime() < MIN_AGE_MS) {
          continue;
        }
        batch.push({ key, canonicalUrl: `${base}${key}`, lastModified });
        if (batch.length >= REFERENCE_BATCH_SIZE) {
          deleted += await this.deleteUnreferencedBatch(batch);
          batch.length = 0;
          if (deleted >= MAX_DELETES_PER_RUN) {
            break outer;
          }
        }
      }

      if (batch.length > 0 && deleted < MAX_DELETES_PER_RUN) {
        deleted += await this.deleteUnreferencedBatch(batch);
      }
    } while (continuationToken && deleted < MAX_DELETES_PER_RUN);

    if (deleted > 0) {
      this.logger.log(`report upload orphan GC finished deleted=${deleted}`);
    }
  }

  private async deleteUnreferencedBatch(
    batch: ReadonlyArray<{ key: string; canonicalUrl: string }>,
  ): Promise<number> {
    if (batch.length === 0) {
      return 0;
    }
    const canonicalUrls = batch.map((b) => b.canonicalUrl);
    const keys = batch.map((b) => b.key);
    const rows = await this.prisma.report.findMany({
      where: {
        OR: [{ mediaUrls: { hasSome: canonicalUrls } }, { mediaUrls: { hasSome: keys } }],
      },
      select: { mediaUrls: true },
    });
    const referenced = collectReferencedKeys(batch, rows);
    let deleted = 0;
    for (const { key } of batch) {
      if (referenced.has(key)) {
        continue;
      }
      try {
        await this.reportsUpload.deleteObjectByKey(key);
        deleted += 1;
        this.logger.log(`orphan_report_media_deleted key=${key}`);
      } catch (err) {
        this.logger.warn(`orphan_report_media_delete_failed key=${key} err=${String(err)}`);
      }
    }
    return deleted;
  }
}
