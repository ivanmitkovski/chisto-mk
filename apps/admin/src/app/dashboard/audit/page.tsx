import { cookies } from 'next/headers';
import { AdminShell } from '@/features/admin-shell';
import { DESKTOP_SIDEBAR_COOKIE_KEY } from '@/features/admin-shell/constants';
import { SectionState } from '@/components/ui';
import { AuditWorkspace } from '@/features/audit/components/audit-workspace';
import { getAuditLog } from '@/features/audit/data/audit-adapter';

type PageProps = {
  searchParams: Promise<{ action?: string; resourceType?: string; actorId?: string; from?: string; to?: string; page?: string }>;
};

export default async function AuditPage(props: PageProps) {
  const searchParams = await props.searchParams;
  const cookieStore = await cookies();
  const initialSidebarCollapsed = cookieStore.get(DESKTOP_SIDEBAR_COOKIE_KEY)?.value === '1';

  const page = Math.max(1, parseInt(searchParams.page ?? '1', 10) || 1);
  const limit = 20;
  const filterParams: Parameters<typeof getAuditLog>[2] = {};
  if (searchParams.action) filterParams.action = searchParams.action;
  if (searchParams.resourceType) filterParams.resourceType = searchParams.resourceType;
  if (searchParams.actorId) filterParams.actorId = searchParams.actorId;
  if (searchParams.from) filterParams.from = searchParams.from;
  if (searchParams.to) filterParams.to = searchParams.to;

  let result: Awaited<ReturnType<typeof getAuditLog>>;
  try {
    result = await getAuditLog(page, limit, Object.keys(filterParams).length > 0 ? filterParams : undefined);
  } catch {
    return (
      <AdminShell title="Audit log" activeItem="audit" initialSidebarCollapsed={initialSidebarCollapsed}>
        <SectionState variant="error" message="Unable to load audit log." />
      </AdminShell>
    );
  }

  return (
    <AdminShell title="Audit log" activeItem="audit" initialSidebarCollapsed={initialSidebarCollapsed}>
      <AuditWorkspace
        initialData={result.data}
        initialMeta={result.meta}
      />
    </AdminShell>
  );
}
