'use client';

import { useTranslations } from 'next-intl';
import { Avatar, Button, Icon } from '@/components/ui';
import { formatAdminDateTime, useAdminBcp47Locale } from '@/lib/i18n';
import styles from './user-detail-header.module.css';

type UserDetailHeaderProps = {
  userId: string;
  firstName: string;
  lastName: string;
  email: string;
  role: string;
  status: string;
  lastActiveAt: string | null;
  avatarUrl?: string | null;
  onCopyId?: () => void;
};

const ROLE_LABEL_KEYS: Record<string, string> = {
  USER: 'filters.roleUser',
  SUPPORT: 'filters.roleSupport',
  ADMIN: 'filters.roleAdmin',
  SUPER_ADMIN: 'filters.roleSuperAdmin',
};

const STATUS_LABEL_KEYS: Record<string, string> = {
  ACTIVE: 'filters.active',
  SUSPENDED: 'filters.suspended',
  DELETED: 'filters.deleted',
};

export function UserDetailHeader({
  userId,
  firstName,
  lastName,
  email,
  role,
  status,
  lastActiveAt,
  avatarUrl = null,
  onCopyId,
}: UserDetailHeaderProps) {
  const t = useTranslations('users');
  const locale = useAdminBcp47Locale();
  const displayName =
    status === 'DELETED' ? t('deletedUser') : `${firstName} ${lastName}`.trim() || email;

  return (
    <header className={styles.root}>
      <div className={styles.avatarWrap} aria-hidden>
        <Avatar name={displayName} imageUrl={avatarUrl} size="lg" />
      </div>
      <div className={styles.main}>
        <h1 className={styles.title}>{displayName}</h1>
        <p className={styles.email}>{email}</p>
        <div className={styles.pills}>
          <span className={styles.rolePill}>{t(ROLE_LABEL_KEYS[role] ?? 'filters.roleUser')}</span>
          <span className={styles.statusPill}>{t(STATUS_LABEL_KEYS[status] ?? 'filters.active')}</span>
        </div>
        <p className={styles.meta}>
          {t('detail.header.lastActive', {
            value: lastActiveAt ? formatAdminDateTime(lastActiveAt, locale) : '—',
          })}
        </p>
        <div className={styles.idRow}>
          <code className={styles.userId}>{userId}</code>
          {onCopyId ? (
            <Button type="button" variant="outline" size="sm" onClick={onCopyId}>
              <Icon name="copy" size={12} aria-hidden />
              {t('detail.header.copyId')}
            </Button>
          ) : null}
        </div>
      </div>
    </header>
  );
}
