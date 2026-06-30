import { getTranslations } from 'next-intl/server';
import { AdminShell } from '@/features/admin-shell';
import { readDashboardShellState } from '@/features/admin-shell/server';
import { SectionState } from '@/components/ui';
import { AuditWorkspace } from '@/features/audit';
import { getAuditLog } from '@/features/audit';
import { ADMIN_PERMISSIONS } from '@/lib/auth/rbac/permissions';
import { requirePagePermission } from '@/lib/auth/rbac/server';

type PageProps = {
  searchParams: Promise<{
    action?: string;
    resourceType?: string;
    resourceId?: string;
    actorId?: string;
    from?: string;
    to?: string;
    page?: string;
  }>;
};

export default async function AuditPage(props: PageProps) {
  await requirePagePermission(ADMIN_PERMISSIONS['audit:read']);
  const tNav = await getTranslations('nav');
  const tErrors = await getTranslations('errors');
  const searchParams = await props.searchParams;
  const { initialSidebarCollapsed } = await readDashboardShellState();

  const page = Math.max(1, parseInt(searchParams.page ?? '1', 10) || 1);
  const limit = 20;
  const filterParams: Parameters<typeof getAuditLog>[2] = {};
  if (searchParams.action) filterParams.action = searchParams.action;
  if (searchParams.resourceType) filterParams.resourceType = searchParams.resourceType;
  if (searchParams.resourceId) filterParams.resourceId = searchParams.resourceId;
  if (searchParams.actorId) filterParams.actorId = searchParams.actorId;
  if (searchParams.from) filterParams.from = searchParams.from;
  if (searchParams.to) filterParams.to = searchParams.to;

  let result: Awaited<ReturnType<typeof getAuditLog>>;
  try {
    result = await getAuditLog(page, limit, Object.keys(filterParams).length > 0 ? filterParams : undefined);
  } catch {
    return (
      <AdminShell title={tNav('audit')} activeItem="audit" initialSidebarCollapsed={initialSidebarCollapsed}>
        <SectionState variant="error" message={tErrors('unableToLoadAudit')} />
      </AdminShell>
    );
  }

  return (
    <AdminShell title={tNav('audit')} activeItem="audit" initialSidebarCollapsed={initialSidebarCollapsed}>
      <AuditWorkspace
        initialData={result.data}
        initialMeta={result.meta}
      />
    </AdminShell>
  );
}
