import { clipboardToNewsBlocks } from '@chisto/news-content';
import { describe, expect, it } from 'vitest';
import { assertValidTranslations } from '../../../../../api/src/news/services/news-posts-validation';
import { normalizeTranslationsBody } from '../../../../../api/src/news/services/news-content-sanitize.service';
import { prepareNewsSavePayload } from './news-save-payload';
import { validateNewsPostForAutosave } from './news-post-policy';
import { emptyTranslations } from '../types';

const RELEASE_MARKDOWN = `> **Snap it. Report it. Clean it.**

Everyone in Macedonia knows a place like this. The dump that appeared at the edge of the neighbourhood and never left.

Chisto.mk exists to make them impossible to ignore.

### Thirty seconds from sight to signal

Reporting takes four steps and about as many breaths:

1. **Photograph the site.** Up to five photos, straight from the camera.
2. **Describe it.** A category and a short, clear headline.
3. **Pin it.** Drag the marker to the exact spot.
4. **Submit.** Done. Your report heads to review.

### Get the app

- **iPhone:** [Download on the App Store](https://apps.apple.com/mk/app/chisto-mk/id6771892086)
- **Android:** [Get it on Google Play](https://play.google.com/store/apps/details?id=mk.chisto.app)

Direct links are also available at [chisto.mk](https://www.chisto.mk/en).

---

This is the first announcement on the Chisto.mk [news page](https://www.chisto.mk/en/news).
`;

describe('news save payload vs API validation', () => {
  it('accepts full release markdown on draft autosave with past schedule in form', () => {
    const imported = clipboardToNewsBlocks({ plain: RELEASE_MARKDOWN, html: '' });
    expect(imported).not.toBeNull();

    const values = {
      slug: 'chisto-mk-mobile-ios-android-2026',
      category: 'release' as const,
      scheduledAt: '2026-07-07T10:00',
      featured: false,
      translations: emptyTranslations(),
    };
    values.translations.en = {
      title: 'A Cleaner Macedonia Is in Your Pocket',
      excerpt: 'Chisto.mk is now free on iOS and Android.',
      body: imported!.blocks,
    };

    expect(
      validateNewsPostForAutosave(values, {
        status: 'draft',
        coverMediaId: null,
        media: [],
      }),
    ).toBeNull();

    const payload = prepareNewsSavePayload(values);
    // Autosave must not send scheduledAt — only translations need draft validation.
    const normalized = normalizeTranslationsBody(payload.translations);
    expect(() => assertValidTranslations(normalized, false)).not.toThrow();
  });

  it('rejects schedule transition when locales are incomplete', () => {
    const values = {
      slug: 'chisto-mk-mobile-ios-android-2026',
      category: 'release' as const,
      scheduledAt: '2099-07-07T10:00',
      featured: false,
      translations: emptyTranslations(),
    };
    values.translations.en = {
      title: 'Title',
      excerpt: 'Excerpt',
      body: [{ type: 'paragraph', text: 'Body' }],
    };

    const payload = prepareNewsSavePayload(values);
    const normalized = normalizeTranslationsBody(payload.translations);
    expect(() => assertValidTranslations(normalized, true)).toThrow();
  });
});
