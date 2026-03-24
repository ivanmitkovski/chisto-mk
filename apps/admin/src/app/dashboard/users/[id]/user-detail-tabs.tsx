'use client';

import { useState } from 'react';
import { Card } from '@/components/ui';
import { UserDetailForm } from './user-detail-form';
import styles from './user-detail-tabs.module.css';

type AuditEntry = {
  id: string;
  createdAt: string;
  action: string;
  resourceType: string;
  resourceId: string | null;
  actorEmail: string | null;
  metadata: unknown;
};

type SessionEntry = {
  id: string;
  createdAt: string;
  deviceInfo: string | null;
  ipAddress: string | null;
  expiresAt: string;
  revokedAt: string | null;
};

type UserDetailTabsProps = {
  userId: string;
  initialFirstName: string;
  initialLastName: string;
  initialRole: string;
  initialStatus: string;
  initialPhoneNumber: string;
  email: string;
  pointsBalance: number;
  reportsCount: number;
  sessionsCount: number;
  audit: { data: AuditEntry[]; meta: { total: number } };
  sessions: SessionEntry[];
};

export function UserDetailTabs(props: UserDetailTabsProps) {
  const [activeTab, setActiveTab] = useState<'profile' | 'sessions' | 'audit'>('profile');

  return (
    <div>
      <div className={styles.tabs} role="tablist">
        <button
          type="button"
          role="tab"
          aria-selected={activeTab === 'profile'}
          className={activeTab === 'profile' ? styles.tabActive : styles.tab}
          onClick={() => setActiveTab('profile')}
        >
          Profile
        </button>
        <button
          type="button"
          role="tab"
          aria-selected={activeTab === 'sessions'}
          className={activeTab === 'sessions' ? styles.tabActive : styles.tab}
          onClick={() => setActiveTab('sessions')}
        >
          Sessions ({props.sessionsCount})
        </button>
        <button
          type="button"
          role="tab"
          aria-selected={activeTab === 'audit'}
          className={activeTab === 'audit' ? styles.tabActive : styles.tab}
          onClick={() => setActiveTab('audit')}
        >
          Audit ({props.audit.meta.total})
        </button>
      </div>

      {activeTab === 'profile' && (
        <UserDetailForm
          userId={props.userId}
          initialFirstName={props.initialFirstName}
          initialLastName={props.initialLastName}
          initialRole={props.initialRole}
          initialStatus={props.initialStatus}
          initialPhoneNumber={props.initialPhoneNumber}
          email={props.email}
          pointsBalance={props.pointsBalance}
          reportsCount={props.reportsCount}
          sessionsCount={props.sessionsCount}
        />
      )}

      {activeTab === 'sessions' && (
        <Card padding="md">
          <table className={styles.table}>
            <thead>
              <tr>
                <th>Created</th>
                <th>Device</th>
                <th>IP</th>
                <th>Expires</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              {props.sessions.map((s) => (
                <tr key={s.id}>
                  <td>{new Date(s.createdAt).toLocaleString()}</td>
                  <td>{s.deviceInfo ?? '—'}</td>
                  <td>{s.ipAddress ?? '—'}</td>
                  <td>{new Date(s.expiresAt).toLocaleString()}</td>
                  <td>{s.revokedAt ? 'Revoked' : 'Active'}</td>
                </tr>
              ))}
            </tbody>
          </table>
          {props.sessions.length === 0 && (
            <p className={styles.empty}>No sessions</p>
          )}
        </Card>
      )}

      {activeTab === 'audit' && (
        <Card padding="md">
          <table className={styles.table}>
            <thead>
              <tr>
                <th>Time</th>
                <th>Action</th>
                <th>Resource</th>
                <th>Actor</th>
              </tr>
            </thead>
            <tbody>
              {props.audit.data.map((a) => (
                <tr key={a.id}>
                  <td>{new Date(a.createdAt).toLocaleString()}</td>
                  <td>{a.action}</td>
                  <td>
                    {a.resourceType}
                    {a.resourceId ? ` · ${a.resourceId}` : ''}
                  </td>
                  <td>{a.actorEmail ?? '—'}</td>
                </tr>
              ))}
            </tbody>
          </table>
          {props.audit.data.length === 0 && (
            <p className={styles.empty}>No audit entries</p>
          )}
        </Card>
      )}
    </div>
  );
}
