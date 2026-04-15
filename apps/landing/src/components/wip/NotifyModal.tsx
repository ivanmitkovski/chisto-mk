"use client";

import {
  useActionState,
  useCallback,
  useEffect,
  useId,
  useRef,
  useState,
  type ReactNode,
} from "react";
import { useFormStatus } from "react-dom";
import type { NotifySignupState } from "@/app/actions/notify-signup";
import { submitNotifySignup } from "@/app/actions/notify-signup";
import type { Locale } from "@/i18n/config";
import type { WipDictionary } from "@/i18n/dictionaries";
import styles from "@/app/wip.module.css";

const NOTIFY_LS_KEY = "chisto.mk.notify";

type Copy = Pick<
  WipDictionary,
  | "notifyTitle"
  | "notifyDescription"
  | "notifyPlaceholder"
  | "notifySubmit"
  | "notifySuccess"
  | "notifyErrorInvalid"
  | "notifyErrorSave"
  | "notifyAlreadySubscribed"
  | "notifyLegalHint"
  | "notifyConsentLabel"
  | "notifyErrorConsent"
  | "notifyTriggerLabel"
  | "notifyTriggerLoadingLabel"
  | "notifySubscribedTriggerLabel"
  | "notifyCloseLabel"
  | "notifyEmailLabel"
  | "notifySubmitPendingLabel"
>;

type Props = {
  locale: Locale;
  copy: Copy;
};

function SubmitButton({
  children,
  disabled,
  pendingLabel,
}: {
  children: ReactNode;
  disabled: boolean;
  pendingLabel: string;
}) {
  const { pending } = useFormStatus();
  return (
    <button
      type="submit"
      className={styles.notifySubmit}
      disabled={pending || disabled}
      aria-busy={pending}
      aria-label={pending ? pendingLabel : undefined}
    >
      {pending ? (
        <span aria-hidden>
          …
        </span>
      ) : (
        children
      )}
    </button>
  );
}

function errorMessage(
  code: NonNullable<Extract<NotifySignupState, { ok: false }>["code"]>,
  copy: Copy,
): string {
  if (code === "invalid") return copy.notifyErrorInvalid;
  if (code === "consent") return copy.notifyErrorConsent;
  if (code === "already") return copy.notifyAlreadySubscribed;
  return copy.notifyErrorSave;
}

function GreenTickIcon({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" aria-hidden>
      <circle cx="12" cy="12" r="11" fill="currentColor" />
      <path
        fill="none"
        stroke="#ffffff"
        strokeWidth="2.25"
        strokeLinecap="round"
        strokeLinejoin="round"
        d="M7 12l3 3 7-7"
      />
    </svg>
  );
}

export function NotifyModal({ locale, copy }: Props) {
  const uid = useId();
  const dialogRef = useRef<HTMLDialogElement>(null);
  const triggerRef = useRef<HTMLButtonElement>(null);
  const closeBtnRef = useRef<HTMLButtonElement>(null);
  const [modalOpen, setModalOpen] = useState(false);
  const [mounted, setMounted] = useState(false);
  const [storedSubscribed, setStoredSubscribed] = useState(false);

  const headingId = `${uid}-notify-title`;
  const descId = `${uid}-notify-desc`;
  const emailId = `${uid}-email`;
  const consentId = `${uid}-consent`;
  const legalHintId = `${uid}-legal-hint`;
  const errorElId = `${uid}-error`;

  const [state, formAction] = useActionState<NotifySignupState | null, FormData>(
    submitNotifySignup,
    null,
  );

  const success = state?.ok === true;
  const failCode = state?.ok === false ? state.code : null;
  const errorId = failCode ? errorElId : undefined;

  useEffect(() => {
    setMounted(true);
    try {
      setStoredSubscribed(localStorage.getItem(NOTIFY_LS_KEY) === "1");
    } catch {
      setStoredSubscribed(false);
    }
  }, []);

  useEffect(() => {
    if (!success) return;
    try {
      localStorage.setItem(NOTIFY_LS_KEY, "1");
    } catch {
      /* private mode */
    }
    setStoredSubscribed(true);
  }, [success]);

  const showSuccessPanel = success || (mounted && storedSubscribed);
  const subscribedOnTrigger = success || (mounted && storedSubscribed);
  /** Before localStorage is read (e.g. after reload), avoid flashing "Notify me". */
  const triggerLoading = !mounted && !success;

  const emailDescribedBy =
    [descId, failCode === "invalid" || failCode === "already" ? errorId : undefined]
      .filter(Boolean)
      .join(" ")
      .trim() || undefined;

  const consentDescribedBy =
    [legalHintId, failCode === "consent" ? errorId : undefined]
      .filter(Boolean)
      .join(" ")
      .trim() || undefined;

  const openModal = useCallback(() => {
    const d = dialogRef.current;
    if (!d) return;
    d.showModal();
    setModalOpen(true);
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        if (showSuccessPanel) {
          closeBtnRef.current?.focus();
          return;
        }
        const input = document.getElementById(emailId);
        if (input && "focus" in input) {
          (input as HTMLInputElement).focus();
        }
      });
    });
  }, [emailId, showSuccessPanel]);

  const closeModal = useCallback(() => {
    dialogRef.current?.close();
  }, []);

  const onDialogClose = useCallback(() => {
    setModalOpen(false);
    requestAnimationFrame(() => {
      triggerRef.current?.focus();
    });
  }, []);

  useEffect(() => {
    if (!success) return;
    const t = window.setTimeout(() => {
      closeBtnRef.current?.focus();
    }, 0);
    return () => window.clearTimeout(t);
  }, [success]);

  return (
    <>
      <div className={styles.notifyTriggerWrap}>
        <button
          ref={triggerRef}
          type="button"
          className={
            triggerLoading
              ? styles.notifyTriggerButtonLoading
              : subscribedOnTrigger
                ? styles.notifyTriggerButtonSubscribed
                : styles.notifyTriggerButton
          }
          onClick={openModal}
          disabled={triggerLoading}
          aria-busy={triggerLoading}
          aria-haspopup="dialog"
          aria-expanded={modalOpen}
          aria-controls={`${uid}-notify-dialog`}
        >
          {triggerLoading ? (
            <span className={styles.notifyTriggerLoadingInner}>
              <span className={styles.notifyTriggerSpinner} aria-hidden />
              {copy.notifyTriggerLoadingLabel}
            </span>
          ) : subscribedOnTrigger ? (
            <span className={styles.notifyTriggerInner}>
              <GreenTickIcon className={styles.notifyTriggerTick} />
              {copy.notifySubscribedTriggerLabel}
            </span>
          ) : (
            copy.notifyTriggerLabel
          )}
        </button>
      </div>

      <dialog
        ref={dialogRef}
        id={`${uid}-notify-dialog`}
        className={styles.notifyDialog}
        aria-labelledby={headingId}
        aria-describedby={showSuccessPanel ? undefined : descId}
        aria-modal="true"
        onClose={onDialogClose}
      >
        <div className={styles.notifyDialogInner}>
          <div className={styles.notifyDialogHeader}>
            <span className={styles.notifyDialogHeaderSpacer} aria-hidden="true" />
            <h2 id={headingId} className={styles.notifyDialogTitle}>
              {copy.notifyTitle}
            </h2>
            <button
              ref={closeBtnRef}
              type="button"
              className={styles.notifyDialogClose}
              onClick={closeModal}
              aria-label={copy.notifyCloseLabel}
            >
              <span aria-hidden className={styles.notifyDialogCloseIcon} />
            </button>
          </div>

          {!showSuccessPanel ? (
            <p id={descId} className={styles.notifyDialogDescription}>
              {copy.notifyDescription}
            </p>
          ) : null}

          {showSuccessPanel ? (
            <div
              className={styles.notifySuccessPanel}
              role="status"
              aria-live="polite"
              aria-atomic="true"
              tabIndex={-1}
            >
              <GreenTickIcon className={styles.notifySuccessTick} />
              <p className={styles.notifyMessage}>{copy.notifySuccess}</p>
            </div>
          ) : (
            <form className={styles.notifyForm} action={formAction} noValidate>
              <input type="hidden" name="locale" value={locale} />
              <div className={styles.notifyField}>
                <label className={styles.notifyFieldLabel} htmlFor={emailId}>
                  {copy.notifyEmailLabel}
                </label>
                <div className={styles.notifyRow}>
                  <input
                    id={emailId}
                    name="email"
                    type="email"
                    inputMode="email"
                    autoComplete="email"
                    required
                    maxLength={254}
                    placeholder={copy.notifyPlaceholder}
                    className={styles.notifyInput}
                    aria-invalid={failCode === "invalid" ? true : undefined}
                    aria-required="true"
                    aria-describedby={emailDescribedBy}
                  />
                  <SubmitButton disabled={success} pendingLabel={copy.notifySubmitPendingLabel}>
                    {copy.notifySubmit}
                  </SubmitButton>
                </div>
              </div>

              <p id={legalHintId} className={styles.notifyLegalHint}>
                {copy.notifyLegalHint}
              </p>

              <label className={styles.notifyConsentRow}>
                <input
                  id={consentId}
                  className={styles.notifyCheckbox}
                  type="checkbox"
                  name="consent"
                  value="yes"
                  required
                  aria-required="true"
                  aria-invalid={failCode === "consent" ? true : undefined}
                  aria-describedby={consentDescribedBy}
                />
                <span className={styles.notifyConsentText}>{copy.notifyConsentLabel}</span>
              </label>

              <div className={styles.notifyErrorSlot}>
                {failCode ? (
                  <p id={errorElId} className={styles.notifyError} role="alert" aria-live="assertive">
                    {errorMessage(failCode, copy)}
                  </p>
                ) : null}
              </div>
            </form>
          )}
        </div>
      </dialog>
    </>
  );
}
