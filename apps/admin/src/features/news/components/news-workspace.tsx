'use client';

import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useTranslations } from 'next-intl';
import { useState } from 'react';
import { Button, Card, DataTable, PageHeader } from '@/components/ui';
import { Can } from '@/lib/auth/rbac';
import type { NewsPostAdminDto } from '../news-api-types';
import styles from './news-workspace.module.css';

type NewsWorkspaceProps = {
  initialPosts: NewsPostAdminDto[];
};

export function NewsWorkspace({ initialPosts }: NewsWorkspaceProps) {
  const t = useTranslations('news');
  const router = useRouter();
  const [posts] = useState(initialPosts);

  const columns = [
    {
      key: 'title',
      header: t('table.title'),
      render: (row: NewsPostAdminDto) => row.translations.en.title || row.slug,
    },
    {
      key: 'status',
      header: t('table.status'),
      render: (row: NewsPostAdminDto) => t(`status.${row.status}`),
    },
    {
      key: 'category',
      header: t('table.category'),
      render: (row: NewsPostAdminDto) => t(`category.${row.category}`),
    },
    {
      key: 'publishedAt',
      header: t('table.published'),
      render: (row: NewsPostAdminDto) =>
        row.publishedAt ? new Date(row.publishedAt).toLocaleDateString() : '—',
    },
    {
      key: 'actions',
      header: '',
      render: (row: NewsPostAdminDto) => (
        <Link href={`/dashboard/news/${row.id}`} className={styles.editLink}>
          {t('table.edit')}
        </Link>
      ),
    },
  ];

  return (
    <div className={styles.root}>
      <PageHeader
        title={t('pageTitle')}
        description={t('pageDescription')}
        actions={
          <Can permission="news:write">
            <Button onClick={() => router.push('/dashboard/news/new')}>{t('actions.new')}</Button>
          </Can>
        }
      />
      <Card padding="md">
        <DataTable columns={columns} data={posts} getRowId={(row) => row.id} emptyMessage={t('table.empty')} />
      </Card>
    </div>
  );
}
