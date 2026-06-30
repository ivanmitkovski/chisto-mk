import { AuditWorkspaceSkeleton } from '@/components/ui';
import { createDashboardLoadingPage } from '@/features/admin-shell/server';

export default async function AuditLoading() {
  return createDashboardLoadingPage({
    activeItem: 'audit',
    children: <AuditWorkspaceSkeleton />,
  });
}
