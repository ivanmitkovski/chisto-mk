'use client';

import Link from 'next/link';
import type { IconName } from '@/components/ui';
import { Icon } from '@/components/ui';
import styles from './quick-actions.module.css';

type QuickAction = {
  href: string;
  label: string;
  icon: IconName;
};

const ACTIONS: QuickAction[] = [
  { href: '/dashboard/reports?status=NEW', label: 'New reports', icon: 'document-text' },
  { href: '/dashboard/reports?status=IN_REVIEW', label: 'In review', icon: 'document-forward' },
  { href: '/dashboard/users', label: 'Users', icon: 'users' },
  { href: '/dashboard/sites', label: 'Sites', icon: 'location' },
  { href: '/dashboard/events', label: 'Events', icon: 'calendar' },
  { href: '/dashboard/audit', label: 'Audit log', icon: 'scroll-text' },
];

type QuickActionsProps = {
  className?: string;
};

export function QuickActions({ className }: QuickActionsProps) {
  return (
    <nav className={`${styles.root} ${className ?? ''}`.trim()} aria-label="Quick actions">
      {ACTIONS.map((action) => (
        <Link key={action.href} href={action.href} className={styles.link}>
          <Icon name={action.icon} size={14} className={styles.icon} />
          <span>{action.label}</span>
          <Icon name="chevron-right" size={12} className={styles.chevron} />
        </Link>
      ))}
    </nav>
  );
}
