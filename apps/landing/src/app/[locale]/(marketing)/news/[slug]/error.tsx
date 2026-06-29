'use client';

import { useTranslations } from 'next-intl';
import { Container } from '@/components/layout/Container';
import { Section } from '@/components/layout/Section';
import { NewsFetchErrorPanel } from '@/components/organisms/NewsPage/NewsFetchErrorPanel';

export default function NewsArticleError() {
  const t = useTranslations('newsPage');

  return (
    <Section>
      <Container>
        <NewsFetchErrorPanel
          title={t('errorTitle')}
          body={t('errorBody')}
          retryLabel={t('errorRetry')}
        />
      </Container>
    </Section>
  );
}
