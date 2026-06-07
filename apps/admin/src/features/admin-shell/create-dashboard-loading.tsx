import { cookies } from 'next/headers';
import { getTranslations } from 'next-intl/server';
import type { ReactNode } from 'react';
import { SkeletonSurface } from '@/components/ui';
import { adminNavigation } from './config/navigation';
import { AdminShell } from './components/admin-shell';
import { DESKTOP_SIDEBAR_COOKIE_KEY } from './constants';
import type { NavItemKey } from './types';

type CreateDashboardLoadingPageOptions = {
  /** When omitted, resolved from the `nav` namespace using [activeItem]. */
  title?: string;
  activeItem: NavItemKey;
  contentMode?: 'default' | 'immersive';
  children: ReactNode;
};

function navTitleKey(activeItem: NavItemKey): string {
  const item = adminNavigation.find((entry) => entry.key === activeItem);
  return item?.labelKey ?? activeItem;
}

export async function createDashboardLoadingPage({
  title,
  activeItem,
  contentMode = 'default',
  children,
}: CreateDashboardLoadingPageOptions) {
  const cookieStore = await cookies();
  const initialSidebarCollapsed = cookieStore.get(DESKTOP_SIDEBAR_COOKIE_KEY)?.value === '1';
  const tNav = await getTranslations('nav');
  const resolvedTitle = title ?? tNav(navTitleKey(activeItem));

  return (
    <AdminShell
      title={resolvedTitle}
      activeItem={activeItem}
      initialSidebarCollapsed={initialSidebarCollapsed}
      contentMode={contentMode}
    >
      <SkeletonSurface>{children}</SkeletonSurface>
    </AdminShell>
  );
}
