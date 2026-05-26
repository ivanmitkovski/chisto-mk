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
  totalPointsEarned: number;
  isPhoneVerified: boolean;
  organizerCertifiedAt: string | null;
  termsAcceptedAt: string | null;
  termsVersion: string | null;
  requiresTermsAcceptance: boolean;
  privacyAcceptedAt: string | null;
  createdAt: string;
  currentAdminRole: string;
  reportsCount: number;
  sessionsCount: number;
  audit: { data: AuditEntry[]; meta: { total: number } };
  sessions: SessionEntry[];
};

export function UserDetailTabs(props: UserDetailTabsProps) {
  const [activeTab, setActiveTab] = useState<'profile' | 'privacy' | 'sessions' | 'audit'>('profile');

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
          aria-selected={activeTab === 'privacy'}
          className={activeTab === 'privacy' ? styles.tabActive : styles.tab}
          onClick={() => setActiveTab('privacy')}
        >
          Privacy & verification
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
          currentAdminRole={props.currentAdminRole}
          reportsCount={props.reportsCount}
          sessionsCount={props.sessionsCount}
        />
      )}

      {activeTab === 'privacy' && (
        <Card padding="md">
          <dl className={styles.privacyGrid}>
            <div>
              <dt>Organizer certification</dt>
              <dd>{props.organizerCertifiedAt ? new Date(props.organizerCertifiedAt).toLocaleString() : 'Not certified'}</dd>
            </div>
            <div>
              <dt>Phone verification</dt>
              <dd>{props.isPhoneVerified ? 'Verified' : 'Not verified'}</dd>
            </div>
            <div>
              <dt>Terms accepted</dt>
              <dd>{props.termsAcceptedAt ? new Date(props.termsAcceptedAt).toLocaleString() : 'Missing'}</dd>
            </div>
            <div>
              <dt>Terms version</dt>
              <dd>{props.termsVersion ?? '—'}</dd>
            </div>
            <div>
              <dt>Privacy accepted</dt>
              <dd>{props.privacyAcceptedAt ? new Date(props.privacyAcceptedAt).toLocaleString() : 'Missing'}</dd>
            </div>
            <div>
              <dt>Requires terms acceptance</dt>
              <dd>{props.requiresTermsAcceptance ? 'Yes' : 'No'}</dd>
            </div>
            <div>
              <dt>Total points earned</dt>
              <dd>{props.totalPointsEarned}</dd>
            </div>
            <div>
              <dt>Created</dt>
              <dd>{new Date(props.createdAt).toLocaleString()}</dd>
            </div>
          </dl>
        </Card>
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
