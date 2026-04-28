import { createHmac } from 'node:crypto';

import { BadRequestException, Injectable, InternalServerErrorException, Logger, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  SiteShareAttributionEventType,
  SiteShareAttributionSource,
  SiteShareChannel,
} from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import { ObservabilityStore } from '../observability/observability.store';
import {
  SITE_SHARE_LINK_TTL_SEC,
  newSiteShareCid,
  signSiteShareLinkToken,
  verifySiteShareLinkToken,
} from './site-share-link-token';

@Injectable()
export class SiteEngagementService {
  private readonly logger = new Logger(SiteEngagementService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
  ) {}

  async ensureSiteExists(siteId: string): Promise<void> {
    const site = await this.prisma.site.findUnique({
      where: { id: siteId },
      select: { id: true },
    });
    if (!site) {
      throw new NotFoundException({
        code: 'SITE_NOT_FOUND',
        message: `Site with id '${siteId}' was not found`,
      });
    }
  }

  async upvote(siteId: string, userId: string): Promise<void> {
    await this.ensureSiteExists(siteId);
    await this.prisma.$transaction(async (tx) => {
      const created = await tx.siteVote.createMany({
        data: [{ siteId, userId }],
        skipDuplicates: true,
      });
      if (created.count > 0) {
        await tx.site.update({
          where: { id: siteId },
          data: { upvotesCount: { increment: 1 } },
        });
      }
    });
  }

  async removeUpvote(siteId: string, userId: string): Promise<void> {
    await this.ensureSiteExists(siteId);
    await this.prisma.$transaction(async (tx) => {
      const deleted = await tx.siteVote.deleteMany({
        where: { siteId, userId },
      });
      if (deleted.count > 0) {
        await tx.site.update({
          where: { id: siteId },
          data: { upvotesCount: { decrement: deleted.count } },
        });
      }
    });
  }

  async save(siteId: string, userId: string): Promise<void> {
    await this.ensureSiteExists(siteId);
    await this.prisma.$transaction(async (tx) => {
      const created = await tx.siteSave.createMany({
        data: [{ siteId, userId }],
        skipDuplicates: true,
      });
      if (created.count > 0) {
        await tx.site.update({
          where: { id: siteId },
          data: { savesCount: { increment: 1 } },
        });
      }
    });
  }

  async unsave(siteId: string, userId: string): Promise<void> {
    await this.ensureSiteExists(siteId);
    await this.prisma.$transaction(async (tx) => {
      const deleted = await tx.siteSave.deleteMany({
        where: { siteId, userId },
      });
      if (deleted.count > 0) {
        await tx.site.update({
          where: { id: siteId },
          data: { savesCount: { decrement: deleted.count } },
        });
      }
    });
  }

  async share(siteId: string, userId: string, channel: SiteShareChannel): Promise<void> {
    await this.ensureSiteExists(siteId);
    await this.prisma.siteShareEvent.create({ data: { siteId, userId, channel } });
  }

  issueShareLink(siteId: string, channel: SiteShareChannel): {
    siteId: string;
    cid: string;
    token: string;
    channel: SiteShareChannel;
    expiresAt: string;
    url: string;
  } {
    const startedAt = Date.now();
    const nowSec = Math.floor(Date.now() / 1000);
    const cid = newSiteShareCid();
    const expiresAt = new Date((nowSec + SITE_SHARE_LINK_TTL_SEC) * 1000);
    const token = signSiteShareLinkToken(this.getShareSecret(), {
      s: siteId,
      c: cid,
      ch: channel,
      iat: nowSec,
      exp: Math.floor(expiresAt.getTime() / 1000),
    });
    const shareBase = this.shareBaseUrl();
    const query = new URLSearchParams({ st: token, cid }).toString();
    const out = {
      siteId,
      cid,
      token,
      channel,
      expiresAt: expiresAt.toISOString(),
      url: `${shareBase}/sites/${encodeURIComponent(siteId)}?${query}`,
    };
    ObservabilityStore.recordShareLinkIssued(Date.now() - startedAt);
    return out;
  }

  async persistIssuedShareLink(input: {
    siteId: string;
    cid: string;
    channel: SiteShareChannel;
    expiresAt: string;
    userId: string;
  }): Promise<void> {
    await this.prisma.siteShareLink.create({
      data: {
        siteId: input.siteId,
        cid: input.cid,
        channel: input.channel,
        expiresAt: new Date(input.expiresAt),
        sharedByUserId: input.userId,
      },
    });
    this.logger.log(
      `site_share_link_issued siteId=${input.siteId} cid=${input.cid} channel=${input.channel}`,
    );
  }

  async ingestAttributionEvent(input: {
    token: string;
    eventType: SiteShareAttributionEventType;
    source: SiteShareAttributionSource;
    ipAddress: string | null;
    userAgent: string | null;
    openedByUserId: string | undefined;
  }): Promise<{ counted: boolean; siteId: string; cid: string }> {
    const startedAt = Date.now();
    const verification = verifySiteShareLinkToken(
      this.getShareSecret(),
      input.token,
      Math.floor(Date.now() / 1000),
    );
    if (!verification.ok) {
      ObservabilityStore.recordShareAttributionEvent({
        durationMs: Date.now() - startedAt,
        counted: false,
        deduped: false,
        invalid: true,
        rateLimited: false,
      });
      if (verification.reason === 'EXPIRED') {
        throw new BadRequestException({
          code: 'SITES_SHARE_TOKEN_EXPIRED',
          message: 'Share token expired',
        });
      }
      throw new BadRequestException({
        code: 'SITES_SHARE_TOKEN_INVALID',
        message: 'Share token invalid',
      });
    }
    const { claims } = verification;
    const ipHash = this.pseudonymizeFingerprint(input.ipAddress);
    const userAgentHash = this.pseudonymizeFingerprint(input.userAgent);
    const dedupeKey = this.dedupeKey(ipHash, userAgentHash);
    const counted = await this.prisma.$transaction(async (tx) => {
      const link = await tx.siteShareLink.findUnique({
        where: { cid: claims.c },
        select: { id: true, siteId: true, countedAt: true, expiresAt: true },
      });
      if (link == null || link.siteId !== claims.s) {
        throw new BadRequestException({
          code: 'SITES_SHARE_TOKEN_NOT_FOUND',
          message: 'Share token not found',
        });
      }
      if (Date.now() > link.expiresAt.getTime()) {
        throw new BadRequestException({
          code: 'SITES_SHARE_TOKEN_EXPIRED',
          message: 'Share token expired',
        });
      }
      const rollingWindowStart = new Date(Date.now() - 60 * 60 * 1000);
      const sourceEventCount = await tx.siteShareAttributionEvent.count({
        where: {
          shareLinkId: link.id,
          source: input.source,
          createdAt: { gte: rollingWindowStart },
        },
      });
      if (sourceEventCount >= 200) {
        ObservabilityStore.recordShareAttributionEvent({
          durationMs: Date.now() - startedAt,
          counted: false,
          deduped: false,
          invalid: false,
          rateLimited: true,
        });
        this.logger.warn(
          `site_share_attribution_rate_limited cid=${claims.c} source=${input.source} eventsLastHour=${sourceEventCount}`,
        );
        return false;
      }
      await tx.siteShareAttributionEvent.createMany({
        data: [
          {
            shareLinkId: link.id,
            eventType: input.eventType,
            source: input.source,
            dedupeKey,
            ipHash,
            userAgentHash,
            openedByUserId: input.openedByUserId ?? null,
          },
        ],
        skipDuplicates: true,
      });
      const claim = await tx.siteShareLink.updateMany({
        where: { id: link.id, countedAt: null },
        data: { countedAt: new Date() },
      });
      if (claim.count > 0) {
        await tx.site.update({
          where: { id: link.siteId },
          data: { sharesCount: { increment: 1 } },
        });
        return true;
      }
      return false;
    });
    this.logger.log(
      `site_share_attribution_ingested eventType=${input.eventType} counted=${counted} siteId=${claims.s} cid=${claims.c}`,
    );
    ObservabilityStore.recordShareAttributionEvent({
      durationMs: Date.now() - startedAt,
      counted,
      deduped: !counted,
      invalid: false,
      rateLimited: false,
    });
    return { counted, siteId: claims.s, cid: claims.c };
  }

  private dedupeKey(ipHash: string | null, userAgentHash: string | null): string {
    const day = new Date().toISOString().slice(0, 10);
    return `${day}:${ipHash ?? 'noip'}:${userAgentHash ?? 'noua'}`;
  }

  private pseudonymizeFingerprint(value: string | null): string | null {
    const normalized = value?.trim();
    if (!normalized) {
      return null;
    }
    return createHmac('sha256', this.getFingerprintSecret()).update(normalized).digest('hex');
  }

  private shareBaseUrl(): string {
    const raw = this.config.get<string>('SHARE_BASE_URL')?.trim();
    const base = raw != null && raw.length > 0 ? raw : 'https://chisto.mk';
    return base.replace(/\/+$/, '');
  }

  private getShareSecret(): Buffer {
    const raw = this.config.get<string>('SITE_SHARE_TOKEN_SECRET')?.trim();
    const nodeEnv = this.config.get<string>('NODE_ENV') ?? 'development';
    if (raw != null && raw.length >= 24) {
      return Buffer.from(raw, 'utf8');
    }
    if (nodeEnv === 'production') {
      this.logger.error('SITE_SHARE_TOKEN_SECRET missing or too short in production');
      throw new InternalServerErrorException({
        code: 'SITES_SHARE_SECRET_MISCONFIG',
        message: 'Server misconfigured',
      });
    }
    this.logger.warn(
      'SITE_SHARE_TOKEN_SECRET missing; using insecure dev default. Set SITE_SHARE_TOKEN_SECRET (>=24 chars).',
    );
    return Buffer.from('dev_only_site_share_secret_min_24', 'utf8');
  }

  private getFingerprintSecret(): Buffer {
    const raw = this.config.get<string>('SITE_SHARE_FINGERPRINT_SECRET')?.trim();
    const nodeEnv = this.config.get<string>('NODE_ENV') ?? 'development';
    if (raw != null && raw.length >= 24) {
      return Buffer.from(raw, 'utf8');
    }
    if (nodeEnv === 'production') {
      this.logger.error('SITE_SHARE_FINGERPRINT_SECRET missing or too short in production');
      throw new InternalServerErrorException({
        code: 'SITES_SHARE_SECRET_MISCONFIG',
        message: 'Server misconfigured',
      });
    }
    return this.getShareSecret();
  }
}
