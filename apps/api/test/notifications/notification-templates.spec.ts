/// <reference types="jest" />
import {
  siteUpvoteCopy,
  siteCommentCopy,
  reportStatusCopy,
  reportMergePrimaryCopy,
  reportMergeChildCopy,
  reportCoReporterCreditCopy,
} from '../../src/notifications/notification-templates';

describe('notification-templates', () => {
  describe('siteUpvoteCopy', () => {
    it('returns English copy', () => {
      const copy = siteUpvoteCopy('en');
      expect(copy.title).toBe('New upvote');
      expect(copy.body).toBeTruthy();
    });

    it('returns Macedonian copy', () => {
      const copy = siteUpvoteCopy('mk');
      expect(copy.title).toBe('Ново гласање');
    });
  });

  describe('siteCommentCopy', () => {
    it('includes preview when provided', () => {
      const copy = siteCommentCopy('en', 'Great report!');
      expect(copy.body).toContain('Great report!');
    });

    it('uses fallback when no preview', () => {
      const copy = siteCommentCopy('en');
      expect(copy.body).toContain('comment');
    });
  });

  describe('reportStatusCopy', () => {
    it('includes status label', () => {
      const copy = reportStatusCopy('en', 'approved');
      expect(copy.body).toContain('approved');
    });

    it('translates status in mk', () => {
      const copy = reportStatusCopy('mk', 'approved');
      expect(copy.body).toContain('одобрена');
    });
  });

  describe('reportMergePrimaryCopy', () => {
    it('includes report number', () => {
      const copy = reportMergePrimaryCopy('en', '#42');
      expect(copy.body).toContain('#42');
    });
  });

  describe('reportMergeChildCopy', () => {
    it('includes report number', () => {
      const copy = reportMergeChildCopy('en', '#42');
      expect(copy.body).toContain('#42');
    });
  });

  describe('reportCoReporterCreditCopy', () => {
    it('includes report number in both locales', () => {
      expect(reportCoReporterCreditCopy('en', '#42').body).toContain('#42');
      expect(reportCoReporterCreditCopy('mk', '#42').body).toContain('#42');
    });
  });
});
