import { describe, expect, it } from 'vitest';
import { NEWS_EMBED_FRAME_SRC_ORIGINS } from '@chisto/news-content/sanitize';
import { buildLandingContentSecurityPolicy } from './content-security-policy';

describe('buildLandingContentSecurityPolicy', () => {
  it('allows trusted news video embeds in frame-src', () => {
    const csp = buildLandingContentSecurityPolicy(false);
    const frameSrc = csp.split('; ').find((directive) => directive.startsWith('frame-src'));

    expect(frameSrc).toBeDefined();
    expect(frameSrc).toContain("frame-src 'self'");
    expect(frameSrc).toContain('https://www.youtube-nocookie.com');
    expect(frameSrc).toContain('https://player.vimeo.com');
    for (const origin of NEWS_EMBED_FRAME_SRC_ORIGINS) {
      expect(frameSrc).toContain(origin);
    }
  });

  it('keeps default-src strict and does not widen frames via default-src', () => {
    const csp = buildLandingContentSecurityPolicy(false);
    expect(csp.startsWith("default-src 'self'")).toBe(true);
    expect(csp).toContain("object-src 'none'");
    expect(csp).toContain("frame-ancestors 'none'");
  });

  it('includes unsafe-eval only in development', () => {
    expect(buildLandingContentSecurityPolicy(true)).toContain("'unsafe-eval'");
    expect(buildLandingContentSecurityPolicy(false)).not.toContain("'unsafe-eval'");
  });
});
