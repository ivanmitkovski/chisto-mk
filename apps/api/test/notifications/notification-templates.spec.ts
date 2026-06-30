/// <reference types="jest" />
import type { AppLocale } from '../../src/common/i18n/app-locale';
import {
  siteUpvoteCopy,
  siteCommentCopy,
  reportStatusCopy,
  reportMergePrimaryCopy,
  reportMergeChildCopy,
  reportCoReporterCreditCopy,
  welcomePushCopy,
  achievementLevelUpCopy,
  nearbyReportCopy,
  siteStatusUpdateCopy,
  adminTestPushCopy,
  formatSiteStatusLabel,
} from '../../src/notifications/util/notification-templates';

const LOCALES: AppLocale[] = ['en', 'mk', 'sq'];

function expectDistinctAcrossLocales(
  fn: (locale: AppLocale) => { title: string; body: string },
) {
  const copies = LOCALES.map((locale) => fn(locale));
  for (const copy of copies) {
    expect(copy.title.trim().length).toBeGreaterThan(0);
    expect(copy.body.trim().length).toBeGreaterThan(0);
  }
  expect(new Set(copies.map((c) => c.title)).size).toBe(3);
}

describe('notification-templates', () => {
  describe('siteUpvoteCopy', () => {
    it('returns distinct non-empty copy for en, mk, sq', () => {
      expectDistinctAcrossLocales((locale) => siteUpvoteCopy(locale));
    });
  });

  describe('siteCommentCopy', () => {
    it('includes preview when provided', () => {
      const copy = siteCommentCopy('en', 'Great report!');
      expect(copy.body).toContain('Great report!');
    });

    it('returns distinct sq copy (not mk fallback)', () => {
      const sq = siteCommentCopy('sq');
      const mk = siteCommentCopy('mk');
      expect(sq.title).not.toBe(mk.title);
    });
  });

  describe('reportStatusCopy', () => {
    it('translates status per locale', () => {
      expect(reportStatusCopy('en', 'approved').body).toContain('approved');
      expect(reportStatusCopy('mk', 'approved').body).toContain('одобрена');
      expect(reportStatusCopy('sq', 'approved').body).toContain('aprobar');
    });
  });

  describe('report merge copy', () => {
    it('includes report number in all locales', () => {
      for (const locale of LOCALES) {
        expect(reportMergePrimaryCopy(locale, '#42').body).toContain('#42');
        expect(reportMergeChildCopy(locale, '#42').body).toContain('#42');
        expect(reportCoReporterCreditCopy(locale, '#42').body).toContain('#42');
      }
    });
  });

  describe('welcomePushCopy', () => {
    it('returns distinct sq welcome', () => {
      expectDistinctAcrossLocales((locale) => welcomePushCopy(locale));
    });
  });

  describe('achievementLevelUpCopy', () => {
    it('embeds level name', () => {
      expect(achievementLevelUpCopy('sq', 'Eko-heroi').body).toContain('Eko-heroi');
    });
  });

  describe('nearbyReportCopy', () => {
    it('returns distinct sq copy', () => {
      expect(nearbyReportCopy('sq').title).not.toBe(nearbyReportCopy('mk').title);
    });
  });

  describe('siteStatusUpdateCopy', () => {
    it('localizes status label', () => {
      const sq = siteStatusUpdateCopy('sq', formatSiteStatusLabel('CLEANED', 'sq'));
      expect(sq.body).toContain('pastrur');
    });
  });

  describe('adminTestPushCopy', () => {
    it('returns distinct sq test push', () => {
      expectDistinctAcrossLocales((locale) => adminTestPushCopy(locale));
    });
  });
});
