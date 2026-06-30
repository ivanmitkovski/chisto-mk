'use client';

import { ReactNode, useState } from 'react';
import { useTranslations } from 'next-intl';
import { Button, Drawer } from '@/components/ui';
import styles from './news-inspector-drawer.module.css';

type NewsInspectorDrawerProps = {
  children: ReactNode;
  incompleteLocaleCount?: number;
};

export function NewsInspectorDrawer({ children, incompleteLocaleCount = 0 }: NewsInspectorDrawerProps) {
  const t = useTranslations('news');
  const [open, setOpen] = useState(false);

  const mobileLabel =
    incompleteLocaleCount > 0
      ? t('editor.inspectorWithIssues', { count: incompleteLocaleCount })
      : t('editor.inspector');

  return (
    <>
      <div className={styles.desktopPanel}>{children}</div>
      <div className={styles.mobileToggle}>
        <Button type="button" variant="outline" size="sm" onClick={() => setOpen(true)}>
          {mobileLabel}
        </Button>
      </div>
      <Drawer open={open} title={t('editor.inspector')} onClose={() => setOpen(false)} side="right">
        {children}
      </Drawer>
    </>
  );
}
