import { Suspense } from 'react';
import { cookies } from 'next/headers';
import { AdminShell } from '@/features/admin-shell';
import { DESKTOP_SIDEBAR_COOKIE_KEY } from '@/features/admin-shell/constants';
import { SectionState } from '@/components/ui';
import { getUsers, getUsersStats } from '@/features/users/data/users-adapter';
import { UsersWorkspace } from '@/features/users/components/users-workspace';

type UsersPageProps = {
  searchParams: Promise<{ search?: string; role?: string; status?: string; page?: string }>;
};

export default async function UsersPage({ searchParams }: UsersPageProps) {
  const cookieStore = await cookies();
  const initialSidebarCollapsed = cookieStore.get(DESKTOP_SIDEBAR_COOKIE_KEY)?.value === '1';
  const params = await searchParams;

  let result: Awaited<ReturnType<typeof getUsers>>;
  let stats: Awaited<ReturnType<typeof getUsersStats>>;

  try {
    const search = params.search?.trim();
    const role = params.role;
    const status = params.status;
    const page = params.page ? Math.max(1, parseInt(params.page, 10)) : 1;

    [result, stats] = await Promise.all([
      getUsers({
        limit: 20,
        page,
        ...(search ? { search } : {}),
        ...(role ? { role } : {}),
        ...(status ? { status } : {}),
      }),
      getUsersStats(),
    ]);
  } catch {
    return (
      <AdminShell title="Users" activeItem="users" initialSidebarCollapsed={initialSidebarCollapsed}>
        <SectionState variant="error" message="Unable to load users. Please sign in again." />
      </AdminShell>
    );
  }

  return (
    <AdminShell title="Users" activeItem="users" initialSidebarCollapsed={initialSidebarCollapsed}>
      <Suspense fallback={<SectionState variant="loading" message="Loading users…" />}>
        <UsersWorkspace
          initialData={result.data}
          initialMeta={result.meta}
          initialStats={stats}
        />
      </Suspense>
    </AdminShell>
  );
}
