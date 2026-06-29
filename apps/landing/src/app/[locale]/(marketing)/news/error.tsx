'use client';

import { useTranslations } from 'next-intl';
import { Container } from '@/components/layout/Container';
import { Section } from '@/components/layout/Section';
import { NewsErrorRetryButton } from '@/components/organisms/NewsPage/NewsErrorRetryButton';

export default function NewsHubError() {
  const t = useTranslations('newsPage');

  return (
    <Section>
      <Container>
        <div
          className="mx-auto max-w-2xl rounded-2xl border border-red-200/90 bg-red-50/90 p-8 shadow-sm md:p-10"
          role="alert"
          aria-live="assertive"
        >
          <h1 className="text-lg font-bold text-gray-900">{t('errorTitle')}</h1>
          <p className="mt-3 leading-relaxed text-gray-600" id="news-hub-error-desc">
            {t('errorBody')}
          </p>
          <p className="mt-6">
            <NewsErrorRetryButton label={t('errorRetry')} ariaDescribedBy="news-hub-error-desc" />
          </p>
        </div>
      </Container>
    </Section>
  );
}
