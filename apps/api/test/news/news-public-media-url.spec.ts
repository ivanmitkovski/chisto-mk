import {
  newsMediaRedirectMaxAgeSeconds,
  publicNewsMediaUrl,
  resolvePublicApiV1Base,
} from '../../src/news/services/news-public-media-url';

describe('news-public-media-url', () => {
  it('defaults to production API v1 base', () => {
    expect(resolvePublicApiV1Base(undefined)).toBe('https://api.chisto.mk/v1');
    expect(resolvePublicApiV1Base('')).toBe('https://api.chisto.mk/v1');
  });

  it('appends /v1 when missing', () => {
    expect(resolvePublicApiV1Base('https://api.chisto.mk')).toBe('https://api.chisto.mk/v1');
    expect(resolvePublicApiV1Base('https://api.chisto.mk/')).toBe('https://api.chisto.mk/v1');
  });

  it('keeps an existing /v1 suffix', () => {
    expect(resolvePublicApiV1Base('https://api.staging.example/v1')).toBe(
      'https://api.staging.example/v1',
    );
  });

  it('builds a stable media path', () => {
    expect(publicNewsMediaUrl('https://api.chisto.mk/v1', 'media-1')).toBe(
      'https://api.chisto.mk/v1/news/media/media-1',
    );
  });

  it('keeps redirect max-age under the signed URL TTL', () => {
    expect(newsMediaRedirectMaxAgeSeconds(3600)).toBe(120);
    expect(newsMediaRedirectMaxAgeSeconds(90)).toBe(30);
    expect(newsMediaRedirectMaxAgeSeconds(60)).toBe(0);
    expect(newsMediaRedirectMaxAgeSeconds(0)).toBe(0);
  });
});
