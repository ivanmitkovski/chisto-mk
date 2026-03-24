'use client';

import { useRouter, useSearchParams } from 'next/navigation';
import Link from 'next/link';
import { useCallback, useEffect, useRef, useState } from 'react';
import { AnimatePresence, motion } from 'framer-motion';
import { Button, Card, Icon, Input, Pagination, Snack } from '@/components/ui';
import { adminBrowserFetch } from '@/lib/admin-browser-api';
import type { UserRow, UsersStats } from '@/features/users/data/users-adapter';
import { ActionConfirmModal } from '@/features/reports/components/action-confirm-modal';
import styles from './users-workspace.module.css';

type UsersWorkspaceProps = {
  initialData: UserRow[];
  initialMeta: { total: number; page: number; limit: number };
  initialStats: UsersStats;
};

const ROLE_OPTIONS = [
  { value: '', label: 'All roles' },
  { value: 'USER', label: 'User' },
  { value: 'MODERATOR', label: 'Moderator' },
  { value: 'ADMIN', label: 'Admin' },
  { value: 'SUPER_ADMIN', label: 'Super Admin' },
];

const STATUS_OPTIONS = [
  { value: '', label: 'All statuses' },
  { value: 'ACTIVE', label: 'Active' },
  { value: 'SUSPENDED', label: 'Suspended' },
];

function statusPillClass(status: string): string {
  const map: Record<string, string> = {
    ACTIVE: styles.statusActive,
    SUSPENDED: styles.statusSuspended,
  };
  return `${styles.statusPill} ${map[status] ?? styles.statusDefault}`;
}

function rolePillClass(role: string): string {
  const map: Record<string, string> = {
    ADMIN: styles.roleAdmin,
    SUPER_ADMIN: styles.roleSuperAdmin,
    MODERATOR: styles.roleModerator,
    USER: styles.roleUser,
  };
  return `${styles.rolePill} ${map[role] ?? styles.roleDefault}`;
}

export function UsersWorkspace({ initialData, initialMeta, initialStats }: UsersWorkspaceProps) {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [data, setData] = useState(initialData);
  const [meta, setMeta] = useState(initialMeta);
  const [stats, setStats] = useState(initialStats);
  const selectAllRef = useRef<HTMLInputElement | null>(null);

  useEffect(() => {
    setData(initialData);
    setMeta(initialMeta);
  }, [initialData, initialMeta]);

  useEffect(() => {
    setStats(initialStats);
  }, [initialStats]);
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());
  const [isBulkLoading, setIsBulkLoading] = useState(false);
  const [snack, setSnack] = useState<{ tone: 'success' | 'error'; title: string; message: string } | null>(null);
  const [bulkModal, setBulkModal] = useState<'suspend' | 'activate' | null>(null);

  const search = searchParams.get('search') ?? '';
  const role = searchParams.get('role') ?? '';
  const status = searchParams.get('status') ?? '';

  const buildUrl = useCallback(
    (updates: { search?: string; role?: string; status?: string; page?: number }) => {
      const sp = new URLSearchParams(searchParams.toString());
      if (updates.search !== undefined) {
        if (updates.search) sp.set('search', updates.search);
        else sp.delete('search');
      }
      if (updates.role !== undefined) {
        if (updates.role) sp.set('role', updates.role);
        else sp.delete('role');
      }
      if (updates.status !== undefined) {
        if (updates.status) sp.set('status', updates.status);
        else sp.delete('status');
      }
      if (updates.page !== undefined) {
        if (updates.page > 1) sp.set('page', String(updates.page));
        else sp.delete('page');
      }
      const q = sp.toString();
      return `/dashboard/users${q ? `?${q}` : ''}`;
    },
    [searchParams],
  );

  const handleSearch = (value: string) => {
    router.push(buildUrl({ search: value, page: 1 }));
  };

  const handleRoleChange = (value: string) => {
    router.push(buildUrl({ role: value, page: 1 }));
  };

  const handleStatusChange = (value: string) => {
    router.push(buildUrl({ status: value, page: 1 }));
  };

  const refresh = useCallback(() => {
    router.refresh();
  }, [router]);

  const toggleSelection = (id: string) => {
    setSelectedIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };

  const toggleAll = () => {
    if (selectedIds.size === data.length) {
      setSelectedIds(new Set());
    } else {
      setSelectedIds(new Set(data.map((u) => u.id)));
    }
  };

  async function runBulkAction(action: 'suspend' | 'activate') {
    if (selectedIds.size === 0) return;
    setIsBulkLoading(true);
    try {
      const res = await adminBrowserFetch<{ updatedCount: number; skippedCount: number }>(
        '/admin/users/bulk',
        {
          method: 'POST',
          body: { userIds: Array.from(selectedIds), action },
        },
      );
      setSnack({
        tone: 'success',
        title: 'Bulk update complete',
        message: `${res.updatedCount} user(s) ${action === 'suspend' ? 'suspended' : 'activated'}.`,
      });
      setSelectedIds(new Set());
      setBulkModal(null);
      refresh();
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Bulk update failed';
      setSnack({ tone: 'error', title: 'Bulk update failed', message: msg });
    } finally {
      setIsBulkLoading(false);
    }
  }

  const allSelected = data.length > 0 && selectedIds.size === data.length;
  const someSelected = selectedIds.size > 0;

  useEffect(() => {
    const el = selectAllRef.current;
    if (el) el.indeterminate = someSelected && !allSelected;
  }, [someSelected, allSelected]);

  return (
    <>
      <div className={styles.layout}>
        <a href="#users-table" className="skipLink">
          Skip to users table
        </a>
        <div className={styles.statsBar}>
          <motion.div
            className={styles.statCard}
            initial={{ opacity: 0, y: 4 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.2 }}
          >
            <span className={styles.statIcon}>
              <Icon name="users" size={18} aria-hidden />
            </span>
            <span className={styles.statValue}>{stats.usersCount}</span>
            <span className={styles.statLabel}>Total users</span>
          </motion.div>
          <motion.div
            className={styles.statCard}
            initial={{ opacity: 0, y: 4 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.2, delay: 0.05 }}
          >
            <span className={styles.statIcon}>
              <Icon name="document-forward" size={18} aria-hidden />
            </span>
            <span className={styles.statValue}>{stats.usersNewLast7d}</span>
            <span className={styles.statLabel}>New (7 days)</span>
          </motion.div>
          <motion.div
            className={styles.statCard}
            initial={{ opacity: 0, y: 4 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.2, delay: 0.1 }}
          >
            <span className={styles.statIcon}>
              <Icon name="shield" size={18} aria-hidden />
            </span>
            <span className={styles.statValue}>{stats.sessionsActive}</span>
            <span className={styles.statLabel}>Active sessions</span>
          </motion.div>
        </div>

        <Card className={styles.tableCard} id="users-table">
          <div className={styles.toolbar}>
            <div className={styles.filters}>
              {/* Search updates the URL (server fetch) on blur or Enter — not debounced live search. */}
              <Input
                type="search"
                placeholder="Search users…"
                defaultValue={search}
                onBlur={(e) => handleSearch(e.target.value.trim())}
                onKeyDown={(e) => {
                  if (e.key === 'Enter') {
                    e.preventDefault();
                    handleSearch((e.currentTarget as HTMLInputElement).value.trim());
                  }
                }}
                className={styles.searchInput}
                aria-label="Search users"
              />
              <select
                value={role}
                onChange={(e) => handleRoleChange(e.target.value)}
                className={styles.filterSelect}
                aria-label="Filter by role"
              >
                {ROLE_OPTIONS.map((o) => (
                  <option key={o.value || '_'} value={o.value}>
                    {o.label}
                  </option>
                ))}
              </select>
              <select
                value={status}
                onChange={(e) => handleStatusChange(e.target.value)}
                className={styles.filterSelect}
                aria-label="Filter by status"
              >
                {STATUS_OPTIONS.map((o) => (
                  <option key={o.value || '_'} value={o.value}>
                    {o.label}
                  </option>
                ))}
              </select>
            </div>
            <Button variant="outline" size="sm" onClick={refresh}>
              Refresh
            </Button>
          </div>

          <AnimatePresence>
          {someSelected && (
            <motion.div
              className={styles.bulkBar}
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: 'auto' }}
              exit={{ opacity: 0, height: 0 }}
            >
              <span className={styles.bulkLabel}>{selectedIds.size} selected</span>
              <div className={styles.bulkActions}>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => setBulkModal('activate')}
                  disabled={isBulkLoading}
                >
                  <Icon name="check" size={12} aria-hidden />
                  Activate
                </Button>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => setBulkModal('suspend')}
                  disabled={isBulkLoading}
                  className={styles.bulkDanger}
                >
                  <Icon name="trash" size={12} aria-hidden />
                  Suspend
                </Button>
                <button type="button" className={styles.bulkClear} onClick={() => setSelectedIds(new Set())}>
                  Clear selection
                </button>
              </div>
            </motion.div>
          )}
          </AnimatePresence>

          <div className={styles.tableWrap}>
            {data.length === 0 ? (
              <div className={styles.empty}>No users match your filters.</div>
            ) : (
              <table className={styles.table}>
                <thead>
                  <tr>
                    <th className={styles.thCheck}>
                      <input
                        ref={selectAllRef}
                        type="checkbox"
                        checked={allSelected}
                        onChange={toggleAll}
                        aria-label="Select all"
                      />
                    </th>
                    <th>Name</th>
                    <th>Email</th>
                    <th>Phone</th>
                    <th>Role</th>
                    <th>Status</th>
                    <th>Points</th>
                    <th className={styles.thActions}>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {data.map((u) => (
                    <tr key={u.id} className={selectedIds.has(u.id) ? styles.rowSelected : ''}>
                      <td className={styles.tdCheck}>
                        <input
                          type="checkbox"
                          checked={selectedIds.has(u.id)}
                          onChange={() => toggleSelection(u.id)}
                          aria-label={`Select ${u.firstName} ${u.lastName}`}
                        />
                      </td>
                      <td>
                        <Link href={`/dashboard/users/${u.id}`} className={styles.nameLink}>
                          {u.firstName} {u.lastName}
                        </Link>
                      </td>
                      <td>{u.email}</td>
                      <td>{u.phoneNumber || '—'}</td>
                      <td>
                        <span className={rolePillClass(u.role)}>{u.role}</span>
                      </td>
                      <td>
                        <span className={statusPillClass(u.status)}>{u.status}</span>
                      </td>
                      <td>{u.pointsBalance}</td>
                      <td className={styles.tdActions}>
                        <Link href={`/dashboard/users/${u.id}`} className={styles.actionLink}>
                          View
                        </Link>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>

          <div className={styles.footer}>
            <p className={styles.meta}>
              {meta.total} user{meta.total !== 1 ? 's' : ''} · page {meta.page}
            </p>
            {meta.total > meta.limit && (
              <Pagination
                totalPages={Math.ceil(meta.total / meta.limit)}
                currentPage={meta.page}
                onPageChange={(p) => router.push(buildUrl({ page: p }))}
              />
            )}
          </div>
        </Card>
      </div>

      <Snack
        snack={snack ? { tone: snack.tone, title: snack.title, message: snack.message } : null}
        onClose={() => setSnack(null)}
      />

      <ActionConfirmModal
        isOpen={bulkModal !== null}
        title={bulkModal === 'suspend' ? 'Suspend users' : 'Activate users'}
        description={
          bulkModal === 'suspend'
            ? `Suspend ${selectedIds.size} selected user(s)? They will not be able to sign in until reactivated.`
            : `Activate ${selectedIds.size} selected user(s)? They will be able to sign in again.`
        }
        confirmLabel={bulkModal === 'suspend' ? 'Suspend' : 'Activate'}
        confirmTone={bulkModal === 'suspend' ? 'danger' : 'default'}
        isConfirming={isBulkLoading}
        onCancel={() => !isBulkLoading && setBulkModal(null)}
        onConfirm={() => bulkModal && runBulkAction(bulkModal)}
      />
    </>
  );
}
