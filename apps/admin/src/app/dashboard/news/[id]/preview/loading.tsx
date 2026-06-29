import { getTranslations } from 'next-intl/server';
import { SectionState } from '@/components/ui';

export default async function NewsPreviewLoading() {
  const t = await getTranslations('news');
  return <SectionState variant="loading" message={t('preview.loading')} />;
}
