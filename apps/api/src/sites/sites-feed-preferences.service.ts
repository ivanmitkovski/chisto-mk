import { Injectable } from '@nestjs/common';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import type { FeedVariant } from './feed/feed-v2.types';
import type { SubmitFeedFeedbackDto } from './dto/submit-feed-feedback.dto';

type FeedUserPrefs = {
  hiddenSiteIds: Set<string>;
  mutedCategories: Map<string, number>;
  seenSiteIds: Map<string, number>;
  updatedAt: number;
};

@Injectable()
export class SitesFeedPreferencesService {
  private readonly feedUserPreferences = new Map<string, FeedUserPrefs>();
  private readonly userVariantMemo = new Map<string, FeedVariant>();

  getFeedVariantForUser(userId: string | undefined): FeedVariant {
    if (!userId) return 'v1';
    return this.userVariantMemo.get(userId) ?? 'v1';
  }

  setVariantMemo(userId: string, variant: FeedVariant): void {
    this.userVariantMemo.set(userId, variant);
  }

  recordImpression(userId: string, siteId: string): void {
    const prefs = this.feedUserPreferences.get(userId) ?? {
      hiddenSiteIds: new Set<string>(),
      mutedCategories: new Map<string, number>(),
      seenSiteIds: new Map<string, number>(),
      updatedAt: Date.now(),
    };
    prefs.seenSiteIds.set(siteId, Date.now());
    if (prefs.seenSiteIds.size > 300) {
      const oldest = [...prefs.seenSiteIds.entries()].sort((a, b) => a[1] - b[1]).slice(0, 80);
      for (const [id] of oldest) {
        prefs.seenSiteIds.delete(id);
      }
    }
    prefs.updatedAt = Date.now();
    this.feedUserPreferences.set(userId, prefs);
  }

  applyFeedFeedbackPreference(
    userId: string,
    siteId: string,
    feedbackType: SubmitFeedFeedbackDto['feedbackType'],
  ): void {
    const prefs = this.feedUserPreferences.get(userId) ?? {
      hiddenSiteIds: new Set<string>(),
      mutedCategories: new Map<string, number>(),
      seenSiteIds: new Map<string, number>(),
      updatedAt: Date.now(),
    };
    if (feedbackType === 'not_relevant') {
      prefs.hiddenSiteIds.add(siteId);
    }
    prefs.updatedAt = Date.now();
    this.feedUserPreferences.set(userId, prefs);
  }

  applyUserPreferences<
    T extends { id: string; latestReportCategory: string | null; rankingScore: number },
  >(rows: T[], user?: AuthenticatedUser): T[] {
    if (!user) return rows;
    const prefs = this.feedUserPreferences.get(user.userId);
    if (!prefs) return rows;
    if (Date.now() - prefs.updatedAt > 7 * 24 * 60 * 60 * 1000) {
      this.feedUserPreferences.delete(user.userId);
      return rows;
    }
    const filtered = rows.filter((row) => !prefs.hiddenSiteIds.has(row.id));
    const now = Date.now();
    return filtered.map((row) => {
      const key = row.latestReportCategory?.toUpperCase() ?? '';
      let penalty = prefs.mutedCategories.get(key) ?? 0;
      const seenAt = prefs.seenSiteIds.get(row.id);
      if (seenAt != null && now - seenAt < 24 * 60 * 60 * 1000) {
        penalty += 0.05;
      }
      if (penalty <= 0) return row;
      return {
        ...row,
        rankingScore: Math.max(0, row.rankingScore - penalty),
      };
    });
  }
}
