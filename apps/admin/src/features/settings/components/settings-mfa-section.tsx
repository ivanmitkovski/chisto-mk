'use client';

import { FormEvent, useEffect, useState } from 'react';
import { useTranslations } from 'next-intl';
import QRCode from 'qrcode';
import { Button, Checkbox, ConfirmDialog, Icon, Input, useToast, Badge } from '@/components/ui';
import { adminBrowserFetch } from '@/lib/api';
import { ApiError } from '@/lib/api';
import styles from './settings-mfa-section.module.css';

type MfaStatus = 'idle' | 'setup' | 'confirming' | 'success' | 'disabling';

type SettingsMfaSectionProps = {
  mfaEnabled: boolean;
  onMfaChange: (enabled: boolean) => void;
};

export function SettingsMfaSection({ mfaEnabled, onMfaChange }: SettingsMfaSectionProps) {
  const t = useTranslations('settings.mfa');
  const tSecurity = useTranslations('settings.security');
  const tCommon = useTranslations('common');
  const [status, setStatus] = useState<MfaStatus>('idle');
  const [setupUri, setSetupUri] = useState<string | null>(null);
  const [setupSecret, setSetupSecret] = useState<string | null>(null);
  const [qrDataUrl, setQrDataUrl] = useState<string | null>(null);
  const [code, setCode] = useState('');
  const [backupCodes, setBackupCodes] = useState<string[]>([]);
  const [backupCodesStored, setBackupCodesStored] = useState(false);
  const [disablePassword, setDisablePassword] = useState('');
  const [showDisableModal, setShowDisableModal] = useState(false);
  const { showToast, clearToast } = useToast();
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
    clearToast();
    try {
      const res = await adminBrowserFetch<{ uri: string; secret: string }>('/auth/me/2fa/setup', {
        method: 'POST',
      });
      setSetupUri(res.uri);
      setSetupSecret(res.secret);
      setCode('');
      setStatus('setup');
    } catch (err) {
      showToast({
        tone: 'error',
        title: tCommon('errorGeneric'),
        message: err instanceof ApiError ? err.message : t('toast.setupError'),
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
      showToast({
        tone: 'warning',
        title: t('toast.enterCodeTitle'),
        message: t('toast.enterCodeMessage'),
      });
      return;
    }

    setBusy(true);
    clearToast();
    try {
      const res = await adminBrowserFetch<{ backupCodes: string[] }>('/auth/me/2fa/enable', {
        method: 'POST',
        body: { code: code.trim() },
      });
      setBackupCodes(res.backupCodes);
      setBackupCodesStored(false);
      setStatus('success');
      onMfaChange(true);
    } catch (err) {
      showToast({
        tone: 'error',
        title: t('toast.verificationFailedTitle'),
        message: err instanceof ApiError ? err.message : t('toast.invalidCodeMessage'),
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
    setBackupCodesStored(false);
  }

  async function copyBackupCodes() {
    if (backupCodes.length === 0) return;
    try {
      await navigator.clipboard.writeText(backupCodes.join('\n'));
      showToast({
        tone: 'success',
        title: t('copyBackupCodesSuccessTitle'),
        message: t('copyBackupCodesSuccessMessage'),
      });
    } catch {
      showToast({
        tone: 'warning',
        title: tCommon('errorGeneric'),
        message: t('copyBackupCodesFailedMessage'),
      });
    }
  }

  function downloadBackupCodes() {
    if (backupCodes.length === 0) return;
    const blob = new Blob([`${backupCodes.join('\n')}\n`], { type: 'text/plain;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const anchor = document.createElement('a');
    anchor.href = url;
    anchor.download = 'chisto-admin-2fa-backup-codes.txt';
    anchor.click();
    URL.revokeObjectURL(url);
  }

  function openDisableModal() {
    setDisablePassword('');
    setShowDisableModal(true);
  }

  async function confirmDisable() {
    if (!disablePassword.trim()) {
      showToast({
        tone: 'warning',
        title: t('passwordRequiredTitle'),
        message: t('passwordRequiredMessage'),
      });
      return;
    }

    setBusy(true);
    clearToast();
    try {
      await adminBrowserFetch('/auth/me/2fa/disable', {
        method: 'POST',
        body: { password: disablePassword },
      });
      setShowDisableModal(false);
      setDisablePassword('');
      showToast({
        tone: 'success',
        title: t('toast.disabledTitle'),
        message: t('toast.disabledMessage'),
      });
      onMfaChange(false);
    } catch (err) {
      showToast({
        tone: 'error',
        title: t('toast.failedTitle'),
        message: err instanceof ApiError ? err.message : t('toast.incorrectPassword'),
      });
    } finally {
      setBusy(false);
    }
  }

  return (
    <>
      <section className={styles.section}>
        <span className={styles.sectionLabel}>{t('sectionLabel')}</span>
        <h3 className={styles.sectionTitle}>{t('title')}</h3>
        <p className={styles.sectionHint}>{t('hint')}</p>

        {!mfaEnabled ? (
          <div className={styles.recommendedCallout}>
            <Badge tone="success">{t('recommendedBadge')}</Badge>
            <p className={styles.recommendedCopy}>{t('recommendedCopy')}</p>
          </div>
        ) : null}

        {status === 'idle' && !showDisableModal && (
          <div className={styles.mfaStatus}>
            <div className={styles.mfaStatusRow}>
              <Icon name="shield" size={20} aria-hidden />
              <span>{mfaEnabled ? t('enabled') : t('disabled')}</span>
            </div>
            {mfaEnabled ? (
              <Button variant="outline" size="sm" onClick={openDisableModal} disabled={busy}>
                {t('disable2fa')}
              </Button>
            ) : (
              <Button size="sm" onClick={() => void startSetup()} disabled={busy}>
                {busy ? t('starting') : t('enable2fa')}
              </Button>
            )}
          </div>
        )}

        <ConfirmDialog
          open={status === 'idle' && showDisableModal}
          title={t('disableConfirmTitle')}
          description={t('disableHint')}
          tone="danger"
          confirmLabel={busy ? t('disabling') : t('disable2fa')}
          isLoading={busy}
          onConfirm={() => void confirmDisable()}
          onClose={() => {
            if (busy) return;
            setShowDisableModal(false);
            setDisablePassword('');
          }}
        >
          <Input
            id="disable-pwd"
            label={tSecurity('currentPassword')}
            type="password"
            autoComplete="current-password"
            value={disablePassword}
            onChange={(e) => setDisablePassword(e.target.value)}
          />
        </ConfirmDialog>

        {status === 'setup' && setupUri && (
          <div className={styles.setupFlow}>
            <p className={styles.setupStep}>{t('setupStep')}</p>
            <div className={styles.qrWrap}>
              {qrDataUrl ? (
                /* eslint-disable-next-line @next/next/no-img-element -- QR data URL, not static asset */
                <img src={qrDataUrl} alt={t('qrAlt')} className={styles.qr} />
              ) : (
                <div className={styles.qrPlaceholder} aria-hidden />
              )}
            </div>
            {setupSecret && (
              <p className={styles.secretHint}>
                {t('manualKey', { secret: setupSecret })}
              </p>
            )}
            <form onSubmit={enableMfa} className={styles.confirmForm}>
              <Input
                id="mfa-code"
                label={t('enterSixDigitCode')}
                type="text"
                inputMode="numeric"
                autoComplete="one-time-code"
                placeholder={t('codePlaceholder')}
                value={code}
                onChange={(e) => setCode(e.target.value.replace(/\D/g, '').slice(0, 6))}
                maxLength={6}
              />
              <div className={styles.setupActions}>
                <Button type="submit" disabled={busy || code.length !== 6}>
                  {busy ? t('verifying') : t('verifyAndEnable')}
                </Button>
                <Button type="button" variant="outline" onClick={cancelSetup} disabled={busy}>
                  {tCommon('cancel')}
                </Button>
              </div>
            </form>
          </div>
        )}

        {status === 'success' && backupCodes.length > 0 && (
          <div className={styles.backupCodesFlow}>
            <p className={styles.backupTitle}>{t('backupCodesTitle')}</p>
            <p className={styles.backupHint}>{t('backupCodesHint')}</p>
            <div className={styles.backupCodesGrid}>
              {backupCodes.map((c, i) => (
                <code key={i} className={styles.backupCode}>
                  {c}
                </code>
              ))}
            </div>
            <div className={styles.backupActions}>
              <Button type="button" variant="outline" size="sm" onClick={() => void copyBackupCodes()}>
                {t('copyBackupCodes')}
              </Button>
              <Button type="button" variant="outline" size="sm" onClick={downloadBackupCodes}>
                {t('downloadBackupCodes')}
              </Button>
            </div>
            <Checkbox
              id="mfa-backup-attestation"
              checked={backupCodesStored}
              onChange={(event) => setBackupCodesStored(event.target.checked)}
              label={t('backupCodesAttestation')}
            />
            <Button onClick={finishSetup} disabled={!backupCodesStored}>
              {t('done')}
            </Button>
          </div>
        )}
      </section>
    </>
  );
}
