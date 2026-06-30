'use client';

import { FormEvent, useEffect, useMemo, useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { useTranslations } from 'next-intl';
import QRCode from 'qrcode';
import { Brand, Button, Checkbox, Field, Input, useToast } from '@/components/ui';
import { PasswordInput } from '@/features/auth/components/password-input';
import { ApiError } from '@/lib/api';
import { validateE164Phone, validateInvitePassword } from '../lib/accept-invite-validation';
import { mapInviteErrorMessage, shouldOfferInviteSignIn } from '../lib/invite-error-messages';
import styles from './accept-invite-flow.module.css';

type InvitePreview = {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  role: string;
  expiresAt: string;
};

type Step = 'loading' | 'invalid' | 'credentials' | 'secure' | 'mfa' | 'backup' | 'done';

type CredentialErrors = {
  password?: string;
  phoneNumber?: string;
};

export function AcceptInviteFlow() {
  const t = useTranslations('acceptInvite');
  const tCommon = useTranslations('common');
  const router = useRouter();
  const searchParams = useSearchParams();
  const { showToast, clearToast } = useToast();

  const inviteId = searchParams.get('id')?.trim() ?? '';
  const inviteToken = searchParams.get('token') ?? '';

  const [step, setStep] = useState<Step>('loading');
  const [enrollMfa, setEnrollMfa] = useState(false);
  const [invite, setInvite] = useState<InvitePreview | null>(null);
  const [password, setPassword] = useState('');
  const [phoneNumber, setPhoneNumber] = useState('');
  const [totpCode, setTotpCode] = useState('');
  const [setupUri, setSetupUri] = useState<string | null>(null);
  const [setupSecret, setSetupSecret] = useState<string | null>(null);
  const [qrDataUrl, setQrDataUrl] = useState<string | null>(null);
  const [backupCodes, setBackupCodes] = useState<string[]>([]);
  const [backupCodesAcknowledged, setBackupCodesAcknowledged] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [errorCode, setErrorCode] = useState<string | undefined>(undefined);
  const [credentialErrors, setCredentialErrors] = useState<CredentialErrors>({});

  useEffect(() => {
    if (!inviteId || !inviteToken) {
      setStep('invalid');
      setError(t('missingParams'));
      return;
    }

    let cancelled = false;
    (async () => {
      try {
        const params = new URLSearchParams({ id: inviteId, token: inviteToken });
        const res = await fetch(`/api/invite/validate?${params.toString()}`, { cache: 'no-store' });
        const payload = (await res.json()) as InvitePreview & { message?: string; code?: string };
        if (!res.ok) {
          const code = typeof payload.code === 'string' ? payload.code : res.status === 429 ? 'TOO_MANY_REQUESTS' : 'HTTP_ERROR';
          const message = mapInviteErrorMessage(
            code,
            'validate',
            t,
            typeof payload.message === 'string' ? payload.message : undefined,
          );
          throw new ApiError(res.status, code, message);
        }
        if (!cancelled) {
          setInvite(payload);
          setStep('credentials');
        }
      } catch (err) {
        if (!cancelled) {
          setStep('invalid');
          if (err instanceof ApiError) {
            setErrorCode(err.code);
            setError(mapInviteErrorMessage(err.code, 'validate', t, err.message));
          } else {
            setError(mapInviteErrorMessage(undefined, 'validate', t));
          }
        }
      }
    })();

    return () => {
      cancelled = true;
    };
  }, [inviteId, inviteToken, t]);

  useEffect(() => {
    if (setupUri) {
      QRCode.toDataURL(setupUri, { width: 200, margin: 2 })
        .then(setQrDataUrl)
        .catch(() => setQrDataUrl(null));
    } else {
      setQrDataUrl(null);
    }
  }, [setupUri]);

  const stepLabels = useMemo(() => {
    if (step === 'credentials' || step === 'secure') {
      return [t('steps.account')];
    }
    if (enrollMfa) {
      if (step === 'mfa') {
        return [t('steps.account'), t('steps.twoFactor')];
      }
      if (step === 'backup') {
        return [t('steps.account'), t('steps.twoFactor'), t('steps.backupCodes')];
      }
    }
    return [t('steps.account')];
  }, [enrollMfa, step, t]);

  function validateCredentials(): CredentialErrors {
    const nextErrors: CredentialErrors = {};
    const passwordError = validateInvitePassword(password, t);
    const phoneError = validateE164Phone(phoneNumber, t);
    if (passwordError) nextErrors.password = passwordError;
    if (phoneError) nextErrors.phoneNumber = phoneError;
    return nextErrors;
  }

  function handleCredentialsSubmit(event: FormEvent) {
    event.preventDefault();
    const nextErrors = validateCredentials();
    if (Object.keys(nextErrors).length > 0) {
      setCredentialErrors(nextErrors);
      setError(t('fixFields'));
      return;
    }

    clearToast();
    setError(null);
    setCredentialErrors({});
    setStep('secure');
  }

  async function handleSetup2FA() {
    setBusy(true);
    clearToast();
    setError(null);
    setEnrollMfa(true);
    try {
      const res = await fetch('/api/invite/begin-mfa', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
        body: JSON.stringify({ id: inviteId, token: inviteToken }),
      });
      const payload = (await res.json()) as { uri?: string; secret?: string; message?: string; code?: string };
      if (!res.ok || !payload.uri || !payload.secret) {
        const code = typeof payload.code === 'string' ? payload.code : res.status === 429 ? 'TOO_MANY_REQUESTS' : 'HTTP_ERROR';
        throw new ApiError(
          res.status,
          code,
          mapInviteErrorMessage(code, 'begin-mfa', t, payload.message),
        );
      }
      setSetupUri(payload.uri);
      setSetupSecret(payload.secret);
      setTotpCode('');
      setStep('mfa');
    } catch (err) {
      setEnrollMfa(false);
      const message =
        err instanceof ApiError
          ? mapInviteErrorMessage(err.code, 'begin-mfa', t, err.message)
          : mapInviteErrorMessage(undefined, 'begin-mfa', t);
      setError(message);
      showToast({ tone: 'error', title: t('toast.setupFailedTitle'), message });
    } finally {
      setBusy(false);
    }
  }

  async function acceptInvite(options?: { totpCode?: string }) {
    const res = await fetch('/api/invite/accept', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
      body: JSON.stringify({
        id: inviteId,
        token: inviteToken,
        password,
        phoneNumber: phoneNumber.trim(),
        ...(options?.totpCode ? { totpCode: options.totpCode } : {}),
      }),
    });
    const payload = (await res.json()) as {
      backupCodes?: string[];
      message?: string;
      code?: string;
    };
    if (!res.ok) {
      const code = typeof payload.code === 'string' ? payload.code : res.status === 429 ? 'TOO_MANY_REQUESTS' : 'HTTP_ERROR';
      throw new ApiError(
        res.status,
        code,
        mapInviteErrorMessage(code, 'accept', t, payload.message),
      );
    }
    return payload;
  }

  async function handleSkip2FA() {
    setBusy(true);
    clearToast();
    setError(null);
    setEnrollMfa(false);
    try {
      await acceptInvite();
      showToast({
        tone: 'success',
        title: t('toast.skipSuccessTitle'),
        message: t('toast.skipSuccessMessage'),
      });
      setStep('done');
      router.replace('/dashboard');
    } catch (err) {
      const message =
        err instanceof ApiError
          ? mapInviteErrorMessage(err.code, 'accept', t, err.message)
          : mapInviteErrorMessage(undefined, 'accept', t);
      if (err instanceof ApiError) {
        setErrorCode(err.code);
      }
      setError(message);
      showToast({ tone: 'error', title: t('toast.verificationFailedTitle'), message });
    } finally {
      setBusy(false);
    }
  }

  async function handleAcceptSubmit(event: FormEvent) {
    event.preventDefault();
    if (totpCode.trim().length !== 6) {
      setError(t('enterTotp'));
      return;
    }

    setBusy(true);
    clearToast();
    setError(null);
    try {
      const payload = await acceptInvite({ totpCode: totpCode.trim() });
      const codes = payload.backupCodes ?? [];
      if (codes.length > 0) {
        setBackupCodes(codes);
        setBackupCodesAcknowledged(false);
        setStep('backup');
        showToast({
          tone: 'success',
          title: t('toast.accountReadyTitle'),
          message: t('toast.accountReadyMessage'),
        });
      } else {
        showToast({
          tone: 'success',
          title: t('toast.skipSuccessTitle'),
          message: t('toast.skipSuccessMessage'),
        });
        setStep('done');
        router.replace('/dashboard');
      }
    } catch (err) {
      const message =
        err instanceof ApiError
          ? mapInviteErrorMessage(err.code, 'accept', t, err.message)
          : mapInviteErrorMessage(undefined, 'accept', t);
      if (err instanceof ApiError) {
        setErrorCode(err.code);
      }
      setError(message);
      showToast({ tone: 'error', title: t('toast.verificationFailedTitle'), message });
    } finally {
      setBusy(false);
    }
  }

  function continueToDashboard() {
    setStep('done');
    router.replace('/dashboard');
  }

  function backToSecureChoice() {
    clearToast();
    setError(null);
    setErrorCode(undefined);
    setSetupUri(null);
    setSetupSecret(null);
    setTotpCode('');
    setStep('secure');
  }

  const showSignInAction = shouldOfferInviteSignIn(errorCode);

  return (
    <main className={styles.root}>
      <div className={styles.card}>
        <Brand />
        {step === 'loading' ? (
          <>
            <h1 className={styles.title}>{t('checkingTitle')}</h1>
            <p className={styles.lead}>{t('checkingLead')}</p>
          </>
        ) : null}

        {step === 'invalid' ? (
          <>
            <h1 className={styles.title}>{t('unavailableTitle')}</h1>
            <p className={styles.error} role="alert">
              {error}
            </p>
            <div className={styles.invalidActions}>
              <Button type="button" variant="outline" onClick={() => router.push('/login')}>
                {t('backToSignIn')}
              </Button>
            </div>
          </>
        ) : null}

        {invite && step !== 'loading' && step !== 'invalid' && step !== 'done' ? (
          <>
            {stepLabels.length > 0 ? (
              <div className={styles.steps} aria-label={t('steps.progressLabel')}>
                {stepLabels.map((label, index) => (
                  <span
                    key={label}
                    className={index === stepLabels.length - 1 ? styles.stepActive : styles.step}
                  >
                    {label}
                  </span>
                ))}
              </div>
            ) : null}
            <h1 className={styles.title}>
              {step === 'secure'
                ? t('secureTitle')
                : step === 'backup'
                  ? t('saveBackupCodesTitle')
                  : t('welcome', { firstName: invite.firstName })}
            </h1>
            <p className={styles.lead}>
              {step === 'credentials'
                ? t('credentialsLead', { email: invite.email })
                : step === 'secure'
                  ? t('secureLead')
                  : step === 'mfa'
                    ? t('mfaLead')
                    : t('backupLead')}
            </p>
          </>
        ) : null}

        {step === 'credentials' ? (
          <form className={styles.form} onSubmit={handleCredentialsSubmit}>
            <Field
              label={t('mobileNumber')}
              htmlFor="invite-phone"
              required
              errorText={credentialErrors.phoneNumber}
            >
              <Input
                id="invite-phone"
                type="tel"
                autoComplete="tel"
                placeholder={t('mobilePlaceholder')}
                value={phoneNumber}
                onChange={(e) => {
                  setPhoneNumber(e.target.value);
                  if (credentialErrors.phoneNumber) {
                    setCredentialErrors((prev) => {
                      const next = { ...prev };
                      delete next.phoneNumber;
                      return next;
                    });
                  }
                }}
                required
              />
            </Field>
            <Field
              label={t('password')}
              htmlFor="invite-password"
              required
              helperText={t('passwordHelper')}
              errorText={credentialErrors.password}
            >
              <PasswordInput
                id="invite-password"
                autoComplete="new-password"
                value={password}
                onChange={(e) => {
                  setPassword(e.target.value);
                  if (credentialErrors.password) {
                    setCredentialErrors((prev) => {
                      const next = { ...prev };
                      delete next.password;
                      return next;
                    });
                  }
                }}
                required
              />
            </Field>
            {error ? (
              <p className={styles.error} role="alert">
                {error}
              </p>
            ) : null}
            <Button type="submit" disabled={busy}>
              {busy ? tCommon('continuing') : t('continue')}
            </Button>
          </form>
        ) : null}

        {step === 'secure' ? (
          <div className={styles.form}>
            <div className={styles.secureChoice}>
              <Button type="button" onClick={() => void handleSetup2FA()} disabled={busy}>
                {busy ? tCommon('continuing') : t('setupTwoFactor')}
              </Button>
              <span className={styles.recommendedPill}>{t('recommended')}</span>
            </div>
            <Button type="button" variant="outline" onClick={() => void handleSkip2FA()} disabled={busy}>
              {busy ? tCommon('continuing') : t('skipForNow')}
            </Button>
            {error ? (
              <p className={styles.error} role="alert">
                {error}
              </p>
            ) : null}
          </div>
        ) : null}

        {step === 'mfa' ? (
          <form className={styles.form} onSubmit={(e) => void handleAcceptSubmit(e)}>
            {qrDataUrl ? (
              <div className={styles.qrWrap}>
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img src={qrDataUrl} alt={t('qrAlt')} width={200} height={200} />
              </div>
            ) : null}
            {setupSecret ? <p className={styles.secret}>{t('manualKey', { secret: setupSecret })}</p> : null}
            <Field label={t('authenticatorCode')} htmlFor="invite-totp" required>
              <Input
                id="invite-totp"
                inputMode="numeric"
                autoComplete="one-time-code"
                value={totpCode}
                onChange={(e) => setTotpCode(e.target.value.replace(/\D/g, '').slice(0, 6))}
                required
              />
            </Field>
            {error ? (
              <p className={styles.error} role="alert">
                {error}
              </p>
            ) : null}
            <div className={styles.mfaActions}>
              <Button type="button" variant="outline" onClick={backToSecureChoice} disabled={busy}>
                {t('backToSecure')}
              </Button>
              {showSignInAction ? (
                <Button type="button" variant="outline" onClick={() => router.push('/login')}>
                  {t('goToSignIn')}
                </Button>
              ) : null}
              <Button type="submit" disabled={busy}>
                {busy ? tCommon('verifying') : t('createAccount')}
              </Button>
            </div>
          </form>
        ) : null}

        {step === 'backup' ? (
          <div className={styles.form}>
            <ul className={styles.backupList}>
              {backupCodes.map((code) => (
                <li key={code}>{code}</li>
              ))}
            </ul>
            <Checkbox
              label={t('backupAck')}
              checked={backupCodesAcknowledged}
              onChange={(e) => setBackupCodesAcknowledged(e.target.checked)}
            />
            <Button type="button" onClick={continueToDashboard} disabled={!backupCodesAcknowledged}>
              {t('continueToDashboard')}
            </Button>
          </div>
        ) : null}
      </div>
    </main>
  );
}
