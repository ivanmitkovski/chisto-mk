import { cookies } from 'next/headers';
import { notFound } from 'next/navigation';
import { AdminShell } from '@/features/admin-shell';
import { DESKTOP_SIDEBAR_COOKIE_KEY } from '@/features/admin-shell/constants';
import { SectionState } from '@/components/ui';
import { ApiError } from '@/lib/api';
import { getUserDetail, getUserAudit, getUserSessions } from '@/features/users/data/users-adapter';
import { UserDetailTabs } from './user-detail-tabs';

type PageProps = { params: Promise<{ id: string }> };

export default async function UserDetailPage(props: PageProps) {
  const { id } = await props.params;
  const cookieStore = await cookies();
  const initialSidebarCollapsed = cookieStore.get(DESKTOP_SIDEBAR_COOKIE_KEY)?.value === '1';

  let user: Awaited<ReturnType<typeof getUserDetail>>;
  try {
    user = await getUserDetail(id);
  } catch (error) {
    if (error instanceof ApiError && (error.code === 'USER_NOT_FOUND' || error.status === 404)) {
      notFound();
    }
    return (
      <AdminShell title="User" activeItem="users" initialSidebarCollapsed={initialSidebarCollapsed}>
        <SectionState variant="error" message="Unable to load user." />
      </AdminShell>
    );
  }

  if (!user || typeof user !== 'object') {
    notFound();
  }

  const u = user as {
    id: string;
    firstName: string;
    lastName: string;
    email: string;
    phoneNumber: string;
    role: string;
    status: string;
    pointsBalance: number;
    reportsCount: number;
    sessionsCount: number;
  };

  let audit: Awaited<ReturnType<typeof getUserAudit>>;
  let sessions: Awaited<ReturnType<typeof getUserSessions>>;
  try {
    [audit, sessions] = await Promise.all([
      getUserAudit(id, 1, 50),
      getUserSessions(id),
    ]);
  } catch {
    audit = { data: [], meta: { page: 1, limit: 50, total: 0 } };
    sessions = [];
  }

  return (
    <AdminShell title={`${u.firstName} ${u.lastName}`} activeItem="users" initialSidebarCollapsed={initialSidebarCollapsed}>
      <UserDetailTabs
        userId={u.id}
        initialFirstName={u.firstName}
        initialLastName={u.lastName}
        initialRole={u.role}
        initialStatus={u.status}
        initialPhoneNumber={u.phoneNumber ?? ''}
        email={u.email}
        pointsBalance={u.pointsBalance}
        reportsCount={u.reportsCount}
        sessionsCount={u.sessionsCount}
        audit={audit}
        sessions={sessions}
      />
    </AdminShell>
  );
}
