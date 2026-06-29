'use client';

import Link from 'next/link';
import Image from 'next/image';
import { useTranslations } from 'next-intl';
import {
  Button,
  DataTable,
  DataTableLink,
  DataTableMobileField,
  type DataTableColumn,
} from '@/components/ui';
import type { NewsPostAdminDto } from '../news-api-types';
import { NEWS_LOCALES } from '../types';
import styles from './news-workspace.module.css';

type NewsListTableProps = {
  data: NewsPostAdminDto[];
  canWriteNews: boolean;
  duplicatingId: string | null;
  isLoading: boolean;
  onDuplicate: (id: string) => void;
};

function statusClass(status: string): string {
  switch (status) {
    case 'published':
      return styles.statusPublished;
    case 'scheduled':
      return styles.statusScheduled;
    case 'archived':
      return styles.statusArchived;
    default:
      return styles.statusDraft;
  }
}

export function NewsListTable({
  data,
  canWriteNews,
  duplicatingId,
  isLoading,
  onDuplicate,
}: NewsListTableProps) {
  const t = useTranslations('news');

  const columns: DataTableColumn<NewsPostAdminDto>[] = [
    {
      key: 'title',
      header: t('table.title'),
      render: (row) => (
        <div className={styles.titleCell}>
          {row.coverImageUrl ? (
            <div className={styles.thumb}>
              <Image src={row.coverImageUrl} alt="" fill className={styles.thumbImage} unoptimized />
            </div>
          ) : (
            <div className={styles.thumbPlaceholder} aria-hidden>
              <span className={styles.thumbPlaceholderIcon}>—</span>
            </div>
          )}
          <div className={styles.titleBody}>
            <DataTableLink href={`/dashboard/news/${row.id}`}>
              {row.translations.en.title || row.slug}
            </DataTableLink>
            {row.featured ? <span className={styles.featuredBadge}>{t('table.featured')}</span> : null}
            <div className={styles.localeChips} aria-label={t('table.locales')}>
              {NEWS_LOCALES.map((loc) => (
                <span
                  key={loc}
                  className={row.localeCompleteness?.[loc] ? styles.chipComplete : styles.chipIncomplete}
                >
                  {loc.toUpperCase()}
                </span>
              ))}
            </div>
          </div>
        </div>
      ),
      renderMobile: (row) => (
        <DataTableMobileField label={t('table.title')}>
          <Link href={`/dashboard/news/${row.id}`} className={styles.titleLink}>
            {row.translations.en.title || row.slug}
          </Link>
        </DataTableMobileField>
      ),
    },
    {
      key: 'status',
      header: t('table.status'),
      render: (row) => (
        <span className={`${styles.statusBadge} ${statusClass(row.status)}`}>
          {t(`status.${row.status}`)}
        </span>
      ),
      renderMobile: (row) => (
        <DataTableMobileField label={t('table.status')}>
          <span className={`${styles.statusBadge} ${statusClass(row.status)}`}>
            {t(`status.${row.status}`)}
          </span>
        </DataTableMobileField>
      ),
    },
    {
      key: 'category',
      header: t('table.category'),
      render: (row) => <span className={styles.categoryText}>{t(`category.${row.category}`)}</span>,
      renderMobile: (row) => (
        <DataTableMobileField label={t('table.category')}>
          {t(`category.${row.category}`)}
        </DataTableMobileField>
      ),
    },
    {
      key: 'publishedAt',
      header: t('table.published'),
      render: (row) => {
        if (row.status === 'scheduled' && row.scheduledAt) {
          return (
            <span className={styles.dateCell}>
              {t('table.scheduledFor', { date: new Date(row.scheduledAt).toLocaleString() })}
            </span>
          );
        }
        return (
          <span className={styles.dateCell}>
            {row.publishedAt ? new Date(row.publishedAt).toLocaleDateString() : '—'}
          </span>
        );
      },
      renderMobile: (row) => (
        <DataTableMobileField label={t('table.published')}>
          {row.status === 'scheduled' && row.scheduledAt
            ? t('table.scheduledFor', { date: new Date(row.scheduledAt).toLocaleString() })
            : row.publishedAt
              ? new Date(row.publishedAt).toLocaleDateString()
              : '—'}
        </DataTableMobileField>
      ),
    },
    {
      key: 'actions',
      header: '',
      mobileHidden: true,
      renderHeader: () => <span className={styles.srOnly}>{t('table.actions')}</span>,
      render: (row) =>
        canWriteNews ? (
          <div className={styles.actionsCell}>
            <Button
              type="button"
              variant="ghost"
              size="sm"
              disabled={duplicatingId === row.id}
              onClick={() => onDuplicate(row.id)}
            >
              {t('actions.duplicate')}
            </Button>
          </div>
        ) : null,
    },
  ];

  return (
    <DataTable
      columns={columns}
      data={data}
      getRowId={(row) => row.id}
      getRowClassName={() => styles.tableRow}
      isLoading={isLoading}
      loadingRowCount={6}
    />
  );
}
