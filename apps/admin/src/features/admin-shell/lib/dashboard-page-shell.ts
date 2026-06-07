import { cookies } from 'next/headers';
import { DESKTOP_SIDEBAR_COOKIE_KEY } from '../constants';

export async function readDashboardShellState(): Promise<{ initialSidebarCollapsed: boolean }> {
  const cookieStore = await cookies();
  return {
    initialSidebarCollapsed: cookieStore.get(DESKTOP_SIDEBAR_COOKIE_KEY)?.value === '1',
  };
}
