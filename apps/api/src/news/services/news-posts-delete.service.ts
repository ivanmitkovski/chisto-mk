import { Injectable, NotFoundException } from '@nestjs/common';
import type { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { AuditService } from '../../audit/services/audit.service';
import { PrismaService } from '../../prisma/prisma.service';
import { S3StorageClient } from '../../storage/util/s3-storage.client';
import { NewsMediaSignedUrlService } from './news-media-signed-url.service';
import { NewsRevalidateService } from './news-revalidate.service';

@Injectable()
export class NewsPostsDeleteService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly signedUrls: NewsMediaSignedUrlService,
    private readonly revalidate: NewsRevalidateService,
    private readonly s3: S3StorageClient,
    private readonly audit?: AuditService,
  ) {}

  async delete(id: string, actor?: AuthenticatedUser) {
    const existing = await this.prisma.newsPost.findUnique({
      where: { id },
      include: { media: true },
    });
    if (!existing) {
      throw new NotFoundException({
        code: 'NEWS_POST_NOT_FOUND',
        message: 'News post not found',
      });
    }

    for (const m of existing.media) {
      this.signedUrls.invalidateKey(m.objectKey);
      if (this.s3.enabled) {
        try {
          await this.s3.deleteObject(m.objectKey);
        } catch {
          // best effort
        }
      }
    }

    await this.prisma.newsPost.delete({ where: { id } });

    await this.audit?.log({
      actorId: actor?.userId ?? null,
      action: 'news.post.delete',
      resourceType: 'NewsPost',
      resourceId: id,
      metadata: { slug: existing.slug },
    });

    void this.revalidate.triggerLandingRevalidate();
  }
}
