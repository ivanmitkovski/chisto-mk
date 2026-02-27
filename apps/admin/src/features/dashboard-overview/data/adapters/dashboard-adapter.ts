import { apiFetch } from '@/lib/api';
import { getAdminAuthTokenFromCookies } from '@/features/auth/lib/admin-auth-server';
import { StatCard } from '../../types';

type AdminOverviewResponse = {
  reportsByStatus: Record<string, number>;
  sitesByStatus: Record<string, number>;
  cleanupEvents: {
    upcoming: number;
    completed: number;
  };
};

export async function getDashboardStats(): Promise<StatCard[]> {
  const token = await getAdminAuthTokenFromCookies();

  const overview = await apiFetch<AdminOverviewResponse>('/admin/overview', {
    method: 'GET',
    authToken: token,
  });

  return [
    {
      id: 'approved',
      label: 'Approved Reports',
      value: overview.reportsByStatus['APPROVED'] ?? 0,
      tone: 'green',
      icon: 'document-forward',
    },
    {
      id: 'new',
      label: 'New Reports',
      value: overview.reportsByStatus['NEW'] ?? 0,
      tone: 'yellow',
      icon: 'document-text',
    },
    {
      id: 'deleted',
      label: 'Deleted Reports',
      value: overview.reportsByStatus['DELETED'] ?? 0,
      tone: 'red',
      icon: 'clipboard-close',
    },
    {
      id: 'in-review',
      label: 'In Review',
      value: overview.reportsByStatus['IN_REVIEW'] ?? 0,
      tone: 'mint',
      icon: 'document-forward',
    },
  ];
}
