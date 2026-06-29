import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { NextIntlClientProvider } from 'next-intl';
import { describe, expect, it } from 'vitest';
import enNews from '@/i18n/messages/en/news.json';
import { NewsLivePreview } from './news-live-preview';
import type { NewsPostFormValues } from '../types';

const values: NewsPostFormValues = {
  slug: 'test-post',
  category: 'release',
  scheduledAt: '',
  featured: false,
  translations: {
    en: { title: 'Preview title', excerpt: 'Preview excerpt', body: [{ type: 'paragraph', text: 'Hello' }] },
    mk: { title: '', excerpt: '', body: [] },
    sq: { title: '', excerpt: '', body: [] },
  },
};

function renderPreview(fullPage = false) {
  return render(
    <NextIntlClientProvider locale="en" messages={{ news: enNews }}>
      <NewsLivePreview
        values={values}
        locale="en"
        media={[]}
        coverImageUrl={null}
        status="draft"
        categoryLabel="Release"
        fullPage={fullPage}
      />
    </NextIntlClientProvider>,
  );
}

describe('NewsLivePreview device presets', () => {
  it('switches max-width when selecting tablet and phone', async () => {
    const user = userEvent.setup();
    renderPreview(true);

    const panel = () => screen.getByRole('tabpanel');
    expect(panel().querySelector('[data-device="desktop"]')).toBeTruthy();

    await user.click(screen.getByRole('tab', { name: 'Tablet' }));
    expect(panel().querySelector('[data-device="tablet"]')).toBeTruthy();
    expect(panel().querySelector('[data-device="desktop"]')).toBeNull();

    await user.click(screen.getByRole('tab', { name: 'Phone' }));
    expect(panel().querySelector('[data-device="phone"]')).toBeTruthy();
  });

  it('renders article content in the active device panel', async () => {
    renderPreview(false);
    expect(screen.getByRole('heading', { level: 1, name: 'Preview title' })).toBeTruthy();
    expect(screen.getByText('Hello')).toBeTruthy();
  });
});
