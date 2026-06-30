import { Injectable } from '@nestjs/common';
import { Prisma } from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditService } from '../../audit/services/audit.service';
import { AuthenticatedUser } from '../../auth/types/authenticated-user.type';

const APP_CONFIG_KEYS = {
  reportCredits: 'app_report_credits_config',
  feedRanking: 'app_feed_ranking_config',
  organizerQuiz: 'app_organizer_quiz_config',
  termsVersion: 'app_terms_version',
} as const;

export type ReportCreditsConfig = {
  dailyCredits: number;
  emergencyWindowHours: number;
  refillIntervalHours: number;
};

export type FeedRankingConfig = {
  defaultVariant: string;
  experimentEnabled: boolean;
};

@Injectable()
export class AdminAppConfigService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit?: AuditService,
  ) {}

  private async getJson<T>(key: string, fallback: T): Promise<T> {
    const row = await this.prisma.systemConfig.findUnique({ where: { key } });
    if (!row?.value) return fallback;
    try {
      return JSON.parse(row.value) as T;
    } catch {
      return fallback;
    }
  }

  private async setJson(key: string, value: unknown, actor: AuthenticatedUser, action: string): Promise<void> {
    await this.prisma.systemConfig.upsert({
      where: { key },
      create: { key, value: JSON.stringify(value) },
      update: { value: JSON.stringify(value) },
    });
    await this.audit?.log({
      actorId: actor.userId,
      action,
      resourceType: 'SystemConfig',
      resourceId: key,
      metadata: value as Prisma.InputJsonValue,
    });
  }

  getReportCredits() {
    return this.getJson<ReportCreditsConfig>(APP_CONFIG_KEYS.reportCredits, {
      dailyCredits: 3,
      emergencyWindowHours: 24,
      refillIntervalHours: 24,
    });
  }

  updateReportCredits(config: ReportCreditsConfig, actor: AuthenticatedUser) {
    return this.setJson(APP_CONFIG_KEYS.reportCredits, config, actor, 'REPORT_CREDITS_CONFIG_UPDATED').then(
      () => config,
    );
  }

  getFeedRanking() {
    return this.getJson<FeedRankingConfig>(APP_CONFIG_KEYS.feedRanking, {
      defaultVariant: 'v2',
      experimentEnabled: false,
    });
  }

  updateFeedRanking(config: FeedRankingConfig, actor: AuthenticatedUser) {
    return this.setJson(APP_CONFIG_KEYS.feedRanking, config, actor, 'FEED_RANKING_CONFIG_UPDATED').then(() => config);
  }

  getOrganizerQuiz(locale = 'en') {
    return this.getJson<Record<string, unknown>>(`${APP_CONFIG_KEYS.organizerQuiz}:${locale}`, { locale, questions: [] });
  }

  updateOrganizerQuiz(locale: string, payload: Record<string, unknown>, actor: AuthenticatedUser) {
    return this.setJson(`${APP_CONFIG_KEYS.organizerQuiz}:${locale}`, payload, actor, 'ORGANIZER_QUIZ_UPDATED').then(
      () => payload,
    );
  }

  async getTermsVersion() {
    const row = await this.prisma.systemConfig.findUnique({ where: { key: APP_CONFIG_KEYS.termsVersion } });
    return { version: row?.value ?? '1' };
  }

  updateTermsVersion(version: string, actor: AuthenticatedUser) {
    return this.setJson(APP_CONFIG_KEYS.termsVersion, version, actor, 'TERMS_VERSION_UPDATED').then(() => ({
      version,
    }));
  }
}
