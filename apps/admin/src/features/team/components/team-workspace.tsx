'use client';

import { useMemo, useState } from 'react';
import { useTranslations } from 'next-intl';
import {
  Badge,
  Button,
  ConfirmDialog,
  DataTable,
  EmptyState,
  PageHeader,
  Pagination,
  StickyTableWrap,
  Toolbar,
} from '@/components/ui';
import type { DataTableColumn } from '@/components/ui';
import { Can } from '@/lib/auth/rbac';
import { useServerSyncedState } from '@/features/admin-shell/hooks/use-server-synced-state';
import { useAdminBcp47Locale } from '@/lib/i18n';
import { inviteStatusTone, teamRoleLabelKey, TEAM_ROLE_OPTIONS } from '../config/team-roles';
import { useTeamMutations } from '../hooks/use-team-mutations';
import type { StaffRole, TeamInvite, TeamStaffMember } from '../types';
import { InviteStaffModal } from './invite-staff-modal';
import styles from './team-workspace.module.css';

const STAFF_PAGE_SIZE = 20;
const INVITE_PAGE_SIZE = 20;

type TeamWorkspaceProps = {
  initialStaff: TeamStaffMember[];
  initialInvites: TeamInvite[];
  currentUserId: string;
};

function formatDate(value: string | null, locale: string): string {
  if (!value) return '—';
  return new Date(value).toLocaleString(locale, { dateStyle: 'medium', timeStyle: 'short' });
}

function formatToken(value: string): string {
  return value
    .replace(/_/g, ' ')
    .toLowerCase()
    .replace(/\b\w/g, (char) => char.toUpperCase());
}

export function TeamWorkspace({ initialStaff, initialInvites, currentUserId }: TeamWorkspaceProps) {
  const t = useTranslations('team');
  const locale = useAdminBcp47Locale();
  const [staff, setStaff] = useServerSyncedState(initialStaff);
  const [invites, setInvites] = useServerSyncedState(initialInvites);
  const [staffPage, setStaffPage] = useState(1);
  const [inviteOpen, setInviteOpen] = useState(false);
  const [revokeTarget, setRevokeTarget] = useState<TeamInvite | null>(null);
  const [statusChangeTarget, setStatusChangeTarget] = useState<{
    member: TeamStaffMember;
    nextStatus: 'ACTIVE' | 'SUSPENDED';
  } | null>(null);
  const [invitePage, setInvitePage] = useState(1);
  const [roleChangeTarget, setRoleChangeTarget] = useState<{
    member: TeamStaffMember;
    nextRole: StaffRole;
  } | null>(null);
  const mutations = useTeamMutations({
    onInvitesChange: setInvites,
    onStaffChange: setStaff,
  });

  const pendingInvites = useMemo(
    () => invites.filter((invite) => invite.status === 'PENDING'),
    [invites],
  );

  const staffTotalPages = Math.max(1, Math.ceil(staff.length / STAFF_PAGE_SIZE));
  const safeStaffPage = Math.min(staffPage, staffTotalPages);

  const paginatedStaff = useMemo(() => {
    const start = (safeStaffPage - 1) * STAFF_PAGE_SIZE;
    return staff.slice(start, start + STAFF_PAGE_SIZE);
  }, [safeStaffPage, staff]);

  const inviteTotalPages = Math.max(1, Math.ceil(invites.length / INVITE_PAGE_SIZE));
  const safeInvitePage = Math.min(invitePage, inviteTotalPages);
  const paginatedInvites = useMemo(() => {
    const start = (safeInvitePage - 1) * INVITE_PAGE_SIZE;
    return invites.slice(start, start + INVITE_PAGE_SIZE);
  }, [invites, safeInvitePage]);

  const teamRoleLabel = (role: StaffRole): string => {
    const key = teamRoleLabelKey(role);
    return key.includes('.') ? t(key) : formatToken(key);
  };

  const staffColumns: DataTableColumn<TeamStaffMember>[] = [
    {
      key: 'name',
      header: t('columns.name'),
      render: (row) => (
        <span className={styles.nameCell}>
          {row.firstName} {row.lastName}
          {row.id === currentUserId ? <span className={styles.selfBadge}>{t('you')}</span> : null}
        </span>
      ),
    },
    {
      key: 'email',
      header: t('columns.email'),
      render: (row) => row.email,
    },
    {
      key: 'role',
      header: t('columns.role'),
      render: (row) => {
        const isSelf = row.id === currentUserId;
        if (isSelf) {
          return <Badge tone="info">{teamRoleLabel(row.role)}</Badge>;
        }

        return (
          <Can permission="team:write" fallback={<Badge tone="info">{teamRoleLabel(row.role)}</Badge>}>
            <select
              className={styles.roleSelect}
              value={row.role}
              aria-label={t('roleForAria', { email: row.email })}
              onChange={(e) => {
                const nextRole = e.target.value as StaffRole;
                if (nextRole === row.role) return;
                setRoleChangeTarget({ member: row, nextRole });
              }}
            >
              {TEAM_ROLE_OPTIONS.map((option) => (
                <option key={option.value} value={option.value}>
                  {t(option.labelKey)}
                </option>
              ))}
            </select>
          </Can>
        );
      },
    },
    {
      key: 'status',
      header: t('columns.status'),
      render: (row) => (
        <Badge tone={row.status === 'ACTIVE' ? 'success' : row.status === 'SUSPENDED' ? 'warning' : 'neutral'}>
          {formatToken(row.status)}
        </Badge>
      ),
    },
    {
      key: 'lastActive',
      header: t('columns.lastActive'),
      render: (row) => formatDate(row.lastActiveAt, locale),
    },
    {
      key: 'actions',
      header: t('columns.actions'),
      mobileHidden: true,
      render: (row) => {
        if (row.id === currentUserId) {
          return <span className={styles.selfHint}>{t('yourAccount')}</span>;
        }

        return (
          <Can permission="team:write">
            <div className={styles.actions}>
              {row.status === 'ACTIVE' ? (
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  disabled={mutations.busy}
                  onClick={() => setStatusChangeTarget({ member: row, nextStatus: 'SUSPENDED' })}
                >
                  {t('suspend')}
                </Button>
              ) : (
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  disabled={mutations.busy || row.status === 'DELETED'}
                  onClick={() => setStatusChangeTarget({ member: row, nextStatus: 'ACTIVE' })}
                >
                  {t('activate')}
                </Button>
              )}
            </div>
          </Can>
        );
      },
    },
  ];

  const inviteColumns: DataTableColumn<TeamInvite>[] = [
    {
      key: 'name',
      header: t('columns.name'),
      render: (row) => `${row.firstName} ${row.lastName}`,
    },
    { key: 'email', header: t('columns.email'), render: (row) => row.email },
    {
      key: 'role',
      header: t('columns.role'),
      render: (row) => teamRoleLabel(row.role),
    },
    {
      key: 'status',
      header: t('columns.status'),
      render: (row) => <Badge tone={inviteStatusTone(row.status)}>{formatToken(row.status)}</Badge>,
    },
    {
      key: 'expires',
      header: t('columns.expires'),
      render: (row) => formatDate(row.expiresAt, locale),
    },
    {
      key: 'actions',
      header: t('columns.actions'),
      mobileHidden: true,
      render: (row) => (
        <Can permission="team:write">
          <div className={styles.actions}>
            {row.status === 'PENDING' ? (
              <>
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  disabled={mutations.busy}
                  onClick={() => void mutations.resendInvite(row.id)}
                >
                  {t('resend')}
                </Button>
                <Button
                  type="button"
                  variant="danger"
                  size="sm"
                  disabled={mutations.busy}
                  onClick={() => setRevokeTarget(row)}
                >
                  {t('revoke')}
                </Button>
              </>
            ) : null}
          </div>
        </Can>
      ),
    },
  ];

  return (
    <div className={styles.stack}>
      <PageHeader
        title={t('pageTitle')}
        description={t('headerDescription')}
      />
      <Toolbar>
        <Can permission="team:write">
          <Button type="button" onClick={() => setInviteOpen(true)}>
            {t('inviteStaff')}
          </Button>
        </Can>
      </Toolbar>

      <section className={styles.section}>
        <h2 className={styles.sectionTitle}>{t('staffSection')}</h2>
        <StickyTableWrap>
          {staff.length === 0 ? (
            <EmptyState title={t('emptyStaffTitle')} description={t('emptyStaffDescription')} />
          ) : (
            <>
              <DataTable
                columns={staffColumns}
                data={paginatedStaff}
                getRowId={(row) => row.id}
                emptyMessage={t('emptyStaffTable')}
                renderMobileCard={(row) => (
                  <div>
                    <strong>
                      {row.firstName} {row.lastName}
                      {row.id === currentUserId ? ` (${t('you')})` : ''}
                    </strong>
                    <p>{row.email}</p>
                    <Badge tone="info">{teamRoleLabel(row.role)}</Badge>
                    {row.id !== currentUserId ? (
                      <Can permission="team:write">
                        <div className={styles.actions}>
                          {row.status === 'ACTIVE' ? (
                            <Button
                              type="button"
                              variant="outline"
                              size="sm"
                              disabled={mutations.busy}
                              onClick={() => setStatusChangeTarget({ member: row, nextStatus: 'SUSPENDED' })}
                            >
                              {t('suspend')}
                            </Button>
                          ) : (
                            <Button
                              type="button"
                              variant="outline"
                              size="sm"
                              disabled={mutations.busy || row.status === 'DELETED'}
                              onClick={() => setStatusChangeTarget({ member: row, nextStatus: 'ACTIVE' })}
                            >
                              {t('activate')}
                            </Button>
                          )}
                        </div>
                      </Can>
                    ) : null}
                  </div>
                )}
              />
              {staff.length > STAFF_PAGE_SIZE ? (
                <div className={styles.paginationFooter}>
                  <p className={styles.meta}>
                    {t('staffMeta', { count: staff.length, page: safeStaffPage })}
                  </p>
                  <Pagination
                    totalPages={staffTotalPages}
                    currentPage={safeStaffPage}
                    onPageChange={setStaffPage}
                  />
                </div>
              ) : null}
            </>
          )}
        </StickyTableWrap>
      </section>

      <section className={styles.section}>
        <h2 className={styles.sectionTitle}>{t('invitationsSection')}</h2>
        <StickyTableWrap>
          {invites.length === 0 ? (
            <EmptyState
              title={t('emptyInvitesTitle')}
              description={t('emptyInvitesDescription')}
            />
          ) : (
            <>
            <DataTable
              columns={inviteColumns}
              data={paginatedInvites}
              getRowId={(row) => row.id}
              emptyMessage={t('emptyInvitesTable')}
              renderMobileCard={(row) => (
                <div>
                  <strong>
                    {row.firstName} {row.lastName}
                  </strong>
                  <p>{row.email}</p>
                  <Can permission="team:write">
                    {row.status === 'PENDING' ? (
                      <div className={styles.actions}>
                        <Button
                          type="button"
                          variant="outline"
                          size="sm"
                          disabled={mutations.busy}
                          onClick={() => void mutations.resendInvite(row.id)}
                        >
                          {t('resend')}
                        </Button>
                        <Button
                          type="button"
                          variant="danger"
                          size="sm"
                          disabled={mutations.busy}
                          onClick={() => setRevokeTarget(row)}
                        >
                          {t('revoke')}
                        </Button>
                      </div>
                    ) : null}
                  </Can>
                </div>
              )}
            />
            {invites.length > INVITE_PAGE_SIZE ? (
              <div className={styles.paginationFooter}>
                <p className={styles.meta}>{t('invitesMeta', { count: invites.length, page: safeInvitePage })}</p>
                <Pagination
                  totalPages={inviteTotalPages}
                  currentPage={safeInvitePage}
                  onPageChange={setInvitePage}
                />
              </div>
            ) : null}
            </>
          )}
        </StickyTableWrap>
        {pendingInvites.length > 0 ? (
          <p>
            {t('pendingInvites', { count: pendingInvites.length })}
          </p>
        ) : null}
      </section>

      <InviteStaffModal
        open={inviteOpen}
        busy={mutations.busy}
        onClose={() => setInviteOpen(false)}
        onSubmit={mutations.inviteStaff}
      />

      <ConfirmDialog
        open={roleChangeTarget != null}
        title={t('confirmRoleTitle')}
        description={
          roleChangeTarget
            ? t('confirmRoleDescription', {
                name: `${roleChangeTarget.member.firstName} ${roleChangeTarget.member.lastName}`,
                role: teamRoleLabel(roleChangeTarget.nextRole),
              })
            : ''
        }
        confirmLabel={t('changeRole')}
        isLoading={mutations.busy}
        onConfirm={() => {
          if (!roleChangeTarget) return;
          const { member, nextRole } = roleChangeTarget;
          void mutations.updateStaffRole(member.id, nextRole).then((ok) => {
            if (ok) {
              setStaff((prev) =>
                prev.map((row) => (row.id === member.id ? { ...row, role: nextRole } : row)),
              );
              setRoleChangeTarget(null);
            } else {
              setStaff((prev) =>
                prev.map((row) => (row.id === member.id ? { ...row, role: member.role } : row)),
              );
            }
          });
        }}
        onClose={() => setRoleChangeTarget(null)}
      />

      <ConfirmDialog
        open={statusChangeTarget != null}
        title={
          statusChangeTarget?.nextStatus === 'SUSPENDED' ? t('confirmSuspendTitle') : t('confirmActivateTitle')
        }
        tone={statusChangeTarget?.nextStatus === 'SUSPENDED' ? 'danger' : 'default'}
        description={
          statusChangeTarget
            ? statusChangeTarget.nextStatus === 'SUSPENDED'
              ? t('confirmSuspendDescription', {
                  name: `${statusChangeTarget.member.firstName} ${statusChangeTarget.member.lastName}`,
                })
              : t('confirmActivateDescription', {
                  name: `${statusChangeTarget.member.firstName} ${statusChangeTarget.member.lastName}`,
                })
            : ''
        }
        confirmLabel={statusChangeTarget?.nextStatus === 'SUSPENDED' ? t('suspend') : t('activate')}
        isLoading={mutations.busy}
        onConfirm={() => {
          if (!statusChangeTarget) return;
          const { member, nextStatus } = statusChangeTarget;
          void mutations.updateStaffStatus(member.id, nextStatus).then((ok) => {
            if (ok) setStatusChangeTarget(null);
          });
        }}
        onClose={() => setStatusChangeTarget(null)}
      />

      <ConfirmDialog
        open={revokeTarget != null}
        title={t('revokeTitle')}
        tone="danger"
        description={
          revokeTarget
            ? t('revokeDescription', { email: revokeTarget.email })
            : ''
        }
        confirmLabel={t('revoke')}
        isLoading={mutations.busy}
        onConfirm={() => {
          if (!revokeTarget) return;
          void mutations.revokeInvite(revokeTarget.id).then((ok) => {
            if (ok) setRevokeTarget(null);
          });
        }}
        onClose={() => setRevokeTarget(null)}
      />
    </div>
  );
}
