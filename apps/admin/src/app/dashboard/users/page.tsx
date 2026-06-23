import type { Metadata } from 'next';
import { getTranslations } from 'next-intl/server';
import { AdminShell } from '@/features/admin-shell';
import { readDashboardShellState } from '@/features/admin-shell/server';
import { SectionState } from '@/components/ui';
import { getUsers, getUsersStats } from '@/features/users';
import { UsersWorkspace } from '@/features/users';
import { ADMIN_PERMISSIONS } from '@/lib/auth/rbac/permissions';
import { requirePagePermission } from '@/lib/auth/rbac/server';
import { handleServerLoadError } from '@/lib/server/handle-server-load-error';

export const metadata: Metadata = {
  title: 'Users',
};

type UsersPageProps = {
  searchParams: Promise<{
    search?: string;
    role?: string;
    status?: string;
    page?: string;
    sort?: string;
    dir?: string;
    lastActiveBefore?: string;
    lastActiveAfter?: string;
    createdAfter?: string;
  }>;
};

export default async function UsersPage({ searchParams }: UsersPageProps) {
  await requirePagePermission(ADMIN_PERMISSIONS['users:read']);
  const tNav = await getTranslations('nav');
  const { initialSidebarCollapsed } = await readDashboardShellState();
  const params = await searchParams;

  let result: Awaited<ReturnType<typeof getUsers>>;
  let stats: Awaited<ReturnType<typeof getUsersStats>>;

  try {
    const search = params.search?.trim();
    const role = params.role;
    const status = params.status;
    const sort = params.sort;
    const dir = params.dir;
    const lastActiveBefore = params.lastActiveBefore;
    const lastActiveAfter = params.lastActiveAfter;
    const createdAfter = params.createdAfter;
    const page = params.page ? Math.max(1, parseInt(params.page, 10)) : 1;

    [result, stats] = await Promise.all([
      getUsers({
        limit: 20,
        page,
        ...(search ? { search } : {}),
        ...(role ? { role } : {}),
        ...(status ? { status } : {}),
        ...(sort ? { sort } : {}),
        ...(dir ? { dir } : {}),
        ...(lastActiveBefore ? { lastActiveBefore } : {}),
        ...(lastActiveAfter ? { lastActiveAfter } : {}),
        ...(createdAfter ? { createdAfter } : {}),
      }),
      getUsersStats(),
    ]);
  } catch (error) {
    const message = await handleServerLoadError(error, { fallbackMessageKey: 'unableToLoadUsers' });
    return (
      <AdminShell title={tNav('users')} activeItem="users" initialSidebarCollapsed={initialSidebarCollapsed}>
        <SectionState variant="error" message={message} />
      </AdminShell>
    );
  }

  return (
    <AdminShell title={tNav('users')} activeItem="users" initialSidebarCollapsed={initialSidebarCollapsed}>
      <UsersWorkspace
        initialData={result.data}
        initialMeta={result.meta}
        initialStats={stats}
      />
    </AdminShell>
  );
}
