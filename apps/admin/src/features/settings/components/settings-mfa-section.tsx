'use client';

import { FormEvent, useEffect, useState } from 'react';
import QRCode from 'qrcode';
import { Button, Icon, Input, Snack, type SnackState } from '@/components/ui';
import { adminBrowserFetch } from '@/lib/admin-browser-api';
import { ApiError } from '@/lib/api';
import styles from './settings-mfa-section.module.css';

type MfaStatus = 'idle' | 'setup' | 'confirming' | 'success' | 'disabling';

type SettingsMfaSectionProps = {
  mfaEnabled: boolean;
  onMfaChange: (enabled: boolean) => void;
};

export function SettingsMfaSection({ mfaEnabled, onMfaChange }: SettingsMfaSectionProps) {
  const [status, setStatus] = useState<MfaStatus>('idle');
  const [setupUri, setSetupUri] = useState<string | null>(null);
  const [setupSecret, setSetupSecret] = useState<string | null>(null);
  const [qrDataUrl, setQrDataUrl] = useState<string | null>(null);
  const [code, setCode] = useState('');
  const [backupCodes, setBackupCodes] = useState<string[]>([]);
  const [disablePassword, setDisablePassword] = useState('');
  const [showDisableModal, setShowDisableModal] = useState(false);
  const [snack, setSnack] = useState<SnackState | null>(null);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    if (setupUri) {
      QRCode.toDataURL(setupUri, { width: 200, margin: 2 })
        .then(setQrDataUrl)
        .catch(() => setQrDataUrl(null));
    } else {
      setQrDataUrl(null);
    }
  }, [setupUri]);

  async function startSetup() {
    setBusy(true);
    setSnack(null);
    try {
      const res = await adminBrowserFetch<{ uri: string; secret: string }>('/auth/me/2fa/setup', {
        method: 'POST',
      });
      setSetupUri(res.uri);
      setSetupSecret(res.secret);
      setCode('');
      setStatus('setup');
    } catch (err) {
      setSnack({
        tone: 'error',
        title: 'Error',
        message: err instanceof ApiError ? err.message : 'Could not start setup',
      });
    } finally {
      setBusy(false);
    }
  }

  function cancelSetup() {
    setStatus('idle');
    setSetupUri(null);
    setSetupSecret(null);
    setCode('');
  }

  async function enableMfa(e: FormEvent) {
    e.preventDefault();
    if (!code.trim() || code.trim().length !== 6) {
      setSnack({
        tone: 'warning',
        title: 'Enter code',
        message: 'Please enter the 6-digit code from your authenticator app.',
      });
      return;
    }

    setBusy(true);
    setSnack(null);
    try {
      const res = await adminBrowserFetch<{ backupCodes: string[] }>('/auth/me/2fa/enable', {
        method: 'POST',
        body: { code: code.trim() },
      });
      setBackupCodes(res.backupCodes);
      setStatus('success');
      onMfaChange(true);
    } catch (err) {
      setSnack({
        tone: 'error',
        title: 'Verification failed',
        message: err instanceof ApiError ? err.message : 'Invalid code. Please try again.',
      });
    } finally {
      setBusy(false);
    }
  }

  function finishSetup() {
    setStatus('idle');
    setSetupUri(null);
    setSetupSecret(null);
    setBackupCodes([]);
  }

  function openDisableModal() {
    setDisablePassword('');
    setShowDisableModal(true);
  }

  async function confirmDisable() {
    if (!disablePassword.trim()) {
      setSnack({
        tone: 'warning',
        title: 'Password required',
        message: 'Please enter your current password to disable 2FA.',
      });
      return;
    }

    setBusy(true);
    setSnack(null);
    try {
      await adminBrowserFetch('/auth/me/2fa/disable', {
        method: 'POST',
        body: { password: disablePassword },
      });
      setShowDisableModal(false);
      setDisablePassword('');
      setSnack({
        tone: 'success',
        title: '2FA disabled',
        message: 'Two-factor authentication has been turned off.',
      });
      onMfaChange(false);
    } catch (err) {
      setSnack({
        tone: 'error',
        title: 'Failed',
        message: err instanceof ApiError ? err.message : 'Incorrect password.',
      });
    } finally {
      setBusy(false);
    }
  }

  return (
    <>
      <section className={styles.section}>
        <span className={styles.sectionLabel}>Two-factor authentication</span>
        <h3 className={styles.sectionTitle}>2FA</h3>
        <p className={styles.sectionHint}>
          Add an extra layer of security by requiring a code from your authenticator app when signing in.
        </p>

        {status === 'idle' && !showDisableModal && (
          <div className={styles.mfaStatus}>
            <div className={styles.mfaStatusRow}>
              <Icon name="shield" size={20} aria-hidden />
              <span>
                {mfaEnabled ? (
                  'Two-factor authentication is on'
                ) : (
                  'Two-factor authentication is off'
                )}
              </span>
            </div>
            {mfaEnabled ? (
              <Button variant="outline" size="sm" onClick={openDisableModal} disabled={busy}>
                Disable 2FA
              </Button>
            ) : (
              <Button size="sm" onClick={() => void startSetup()} disabled={busy}>
                {busy ? 'Starting…' : 'Enable 2FA'}
              </Button>
            )}
          </div>
        )}

        {status === 'idle' && showDisableModal && (
          <form className={styles.disableForm} onSubmit={(e) => { e.preventDefault(); void confirmDisable(); }}>
            <p className={styles.disableHint}>Enter your password to turn off two-factor authentication.</p>
            <Input
              id="disable-pwd"
              label="Current password"
              type="password"
              autoComplete="current-password"
              value={disablePassword}
              onChange={(e) => setDisablePassword(e.target.value)}
            />
            <div className={styles.disableActions}>
              <Button type="submit" disabled={busy || !disablePassword.trim()}>
                {busy ? 'Disabling…' : 'Disable 2FA'}
              </Button>
              <Button type="button" variant="outline" onClick={() => { setShowDisableModal(false); setDisablePassword(''); }} disabled={busy}>
                Cancel
              </Button>
            </div>
          </form>
        )}

        {status === 'setup' && setupUri && (
          <div className={styles.setupFlow}>
            <p className={styles.setupStep}>Scan with your authenticator app (e.g. Google Authenticator, 1Password)</p>
            <div className={styles.qrWrap}>
              {qrDataUrl ? (
                /* eslint-disable-next-line @next/next/no-img-element -- QR data URL, not static asset */
                <img src={qrDataUrl} alt="QR code for authenticator setup" className={styles.qr} />
              ) : (
                <div className={styles.qrPlaceholder} aria-hidden />
              )}
            </div>
            {setupSecret && (
              <p className={styles.secretHint}>
                Or enter this code manually: <code className={styles.secret}>{setupSecret}</code>
              </p>
            )}
            <form onSubmit={enableMfa} className={styles.confirmForm}>
              <Input
                id="mfa-code"
                label="Enter the 6-digit code"
                type="text"
                inputMode="numeric"
                autoComplete="one-time-code"
                placeholder="000000"
                value={code}
                onChange={(e) => setCode(e.target.value.replace(/\D/g, '').slice(0, 6))}
                maxLength={6}
              />
              <div className={styles.setupActions}>
                <Button type="submit" disabled={busy || code.length !== 6}>
                  {busy ? 'Verifying…' : 'Verify and enable'}
                </Button>
                <Button type="button" variant="outline" onClick={cancelSetup} disabled={busy}>
                  Cancel
                </Button>
              </div>
            </form>
          </div>
        )}

        {status === 'success' && backupCodes.length > 0 && (
          <div className={styles.backupCodesFlow}>
            <p className={styles.backupTitle}>Save your backup codes</p>
            <p className={styles.backupHint}>
              Store these codes in a safe place. Each can be used once if you lose access to your authenticator app.
            </p>
            <div className={styles.backupCodesGrid}>
              {backupCodes.map((c, i) => (
                <code key={i} className={styles.backupCode}>
                  {c}
                </code>
              ))}
            </div>
            <Button onClick={finishSetup}>Done</Button>
          </div>
        )}
      </section>

      <Snack snack={snack} onClose={() => setSnack(null)} />
    </>
  );
}
