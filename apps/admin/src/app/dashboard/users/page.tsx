import { cookies } from 'next/headers';
import { getTranslations } from 'next-intl/server';
import { AdminShell } from '@/features/admin-shell';
import { DESKTOP_SIDEBAR_COOKIE_KEY } from '@/features/admin-shell';
import { SectionState } from '@/components/ui';
import { getUsers, getUsersStats } from '@/features/users';
import { UsersWorkspace } from '@/features/users';
import { ADMIN_PERMISSIONS } from '@/lib/auth/rbac/permissions';
import { requirePagePermission } from '@/lib/auth/rbac/server';

type UsersPageProps = {
  searchParams: Promise<{
    search?: string;
    role?: string;
    status?: string;
    page?: string;
    sort?: string;
    dir?: string;
  }>;
};

export default async function UsersPage({ searchParams }: UsersPageProps) {
  await requirePagePermission(ADMIN_PERMISSIONS['users:read']);
  const tNav = await getTranslations('nav');
  const tErrors = await getTranslations('errors');
  const cookieStore = await cookies();
  const initialSidebarCollapsed = cookieStore.get(DESKTOP_SIDEBAR_COOKIE_KEY)?.value === '1';
  const params = await searchParams;

  let result: Awaited<ReturnType<typeof getUsers>>;
  let stats: Awaited<ReturnType<typeof getUsersStats>>;

  try {
    const search = params.search?.trim();
    const role = params.role;
    const status = params.status;
    const sort = params.sort;
    const dir = params.dir;
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
      }),
      getUsersStats(),
    ]);
  } catch {
    return (
      <AdminShell title={tNav('users')} activeItem="users" initialSidebarCollapsed={initialSidebarCollapsed}>
        <SectionState variant="error" message={tErrors('unableToLoadUsers')} />
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
