'use client';

import { useRouter } from 'next/navigation';
import { useState } from 'react';
import { Button, Card, Snack, type SnackState } from '@/components/ui';
import { adminBrowserFetch } from '@/lib/admin-browser-api';
import { ApiError } from '@/lib/api';
import styles from './user-detail-form.module.css';

type UserDetailFormProps = {
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
};

export function UserDetailForm({
  userId,
  initialFirstName,
  initialLastName,
  initialRole,
  initialStatus,
  initialPhoneNumber,
  email,
  pointsBalance,
  reportsCount,
  sessionsCount,
}: UserDetailFormProps) {
  const router = useRouter();
  const [firstName, setFirstName] = useState(initialFirstName);
  const [lastName, setLastName] = useState(initialLastName);
  const [phoneNumber, setPhoneNumber] = useState(initialPhoneNumber ?? '');
  const [role, setRole] = useState(initialRole);
  const [status, setStatus] = useState(initialStatus);
  const [saving, setSaving] = useState(false);
  const [snack, setSnack] = useState<SnackState | null>(null);

  function validate(): string | null {
    if (!firstName.trim()) return 'First name is required';
    if (!lastName.trim()) return 'Last name is required';
    if (phoneNumber.trim() && phoneNumber.trim().length < 8) return 'Phone must be at least 8 characters';
    return null;
  }

  async function save() {
    const err = validate();
    if (err) {
      setSnack({ tone: 'warning', title: 'Validation', message: err });
      return;
    }
    setSaving(true);
    setSnack(null);
    try {
      await adminBrowserFetch(`/admin/users/${userId}`, {
        method: 'PATCH',
        body: { firstName: firstName.trim(), lastName: lastName.trim(), phoneNumber: phoneNumber.trim() || null, role, status },
      });
      setSnack({ tone: 'success', title: 'Saved', message: 'User updated.' });
      router.refresh();
    } catch (e) {
      const msg = e instanceof ApiError ? e.message : 'Update failed';
      setSnack({ tone: 'warning', title: 'Error', message: msg });
    } finally {
      setSaving(false);
    }
  }

  return (
    <Card className={styles.card} padding="md">
      <div className={styles.grid}>
        <div>
          <p className={styles.label}>Email</p>
          <p className={styles.value}>{email}</p>
        </div>
        <div>
          <p className={styles.label}>Points</p>
          <p className={styles.value}>{pointsBalance}</p>
        </div>
        <div>
          <p className={styles.label}>Reports</p>
          <p className={styles.value}>{reportsCount}</p>
        </div>
        <div>
          <p className={styles.label}>Sessions</p>
          <p className={styles.value}>{sessionsCount}</p>
        </div>
      </div>
      <div className={styles.formRow}>
        <label className={styles.field} htmlFor="user-firstName">
          <span className={styles.label}>First name</span>
          <input
            id="user-firstName"
            type="text"
            className={styles.input}
            value={firstName}
            onChange={(e) => setFirstName(e.target.value)}
            maxLength={100}
          />
        </label>
        <label className={styles.field} htmlFor="user-lastName">
          <span className={styles.label}>Last name</span>
          <input
            id="user-lastName"
            type="text"
            className={styles.input}
            value={lastName}
            onChange={(e) => setLastName(e.target.value)}
            maxLength={100}
          />
        </label>
        <label className={styles.field} htmlFor="user-phone">
          <span className={styles.label}>Phone</span>
          <input
            id="user-phone"
            type="tel"
            className={styles.input}
            value={phoneNumber}
            onChange={(e) => setPhoneNumber(e.target.value)}
            maxLength={20}
          />
        </label>
        <label className={styles.field} htmlFor="user-role">
          <span className={styles.label}>Role</span>
          <select
            id="user-role"
            className={styles.select}
            value={role}
            onChange={(e) => setRole(e.target.value)}
          >
            <option value="USER">USER</option>
            <option value="SUPPORT">SUPPORT</option>
            <option value="ADMIN">ADMIN</option>
            <option value="SUPER_ADMIN">SUPER_ADMIN</option>
          </select>
        </label>
        <label className={styles.field} htmlFor="user-status">
          <span className={styles.label}>Status</span>
          <select
            id="user-status"
            className={styles.select}
            value={status}
            onChange={(e) => setStatus(e.target.value)}
          >
            <option value="ACTIVE">ACTIVE</option>
            <option value="SUSPENDED">SUSPENDED</option>
            <option value="DELETED">DELETED</option>
          </select>
        </label>
      </div>
      <Button type="button" onClick={() => void save()} disabled={saving}>
        {saving ? 'Saving…' : 'Save changes'}
      </Button>
      <Snack snack={snack} onClose={() => setSnack(null)} />
    </Card>
  );
}
