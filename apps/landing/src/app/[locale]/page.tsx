import Image from "next/image";
import { notFound } from "next/navigation";
import { locales, isLocale, type Locale } from "@/i18n/config";
import { getDictionary } from "@/i18n/dictionaries";
import { LanguageSwitcher } from "@/components/wip/LanguageSwitcher";
import { NotifyModal } from "@/components/wip/NotifyModal";
import { ReleaseCountdown } from "@/components/wip/ReleaseCountdown";
import styles from "../wip.module.css";

export function generateStaticParams() {
  return locales.map((locale) => ({ locale }));
}

type Props = {
  params: Promise<{ locale: string }>;
};

export default async function WorkInProgressPage({ params }: Props) {
  const { locale: raw } = await params;
  if (!isLocale(raw)) notFound();
  const locale: Locale = raw;
  const d = getDictionary(locale);

  return (
    <main className={styles.page}>
      <a href="#main-content" className="skip-link">
        {d.skipToContent}
      </a>
      <div className={styles.bg} aria-hidden>
        <div className={styles.bgBloom1} />
        <div className={styles.bgBloom2} />
        <div className={styles.bgGrid} />
        <div className={styles.bgFade} />
      </div>

      <header className={styles.topBar}>
        <LanguageSwitcher currentLocale={locale} ariaLabel={d.languageSelectAria} />
      </header>

      <div id="main-content" className={styles.content} tabIndex={-1}>
        <div className={styles.logoWrap}>
          <Image
            src="/brand/logo.svg"
            alt="Chisto.mk"
            className={styles.logo}
            width={271}
            height={313}
            priority
            unoptimized
          />
        </div>

        <h1 className={styles.title}>Chisto.mk</h1>

        <p className={styles.launchDate}>{d.launchDate}</p>

        <ReleaseCountdown
          countdownDays={d.countdownDays}
          countdownHours={d.countdownHours}
          countdownMinutes={d.countdownMinutes}
          countdownSeconds={d.countdownSeconds}
          countdownAria={d.countdownAria}
          liveMessage={d.liveMessage}
          countdownLoadingStatus={d.countdownLoadingStatus}
        />

        <p className={styles.badge}>
          <span className={styles.badgeDot} aria-hidden />
          {d.badge}
        </p>

        <p className={styles.lead}>{d.lead}</p>

        <div className={styles.divider} aria-hidden />

        <p className={styles.meta}>
          <strong>{d.metaStrong}</strong>
          <br />
          {d.metaLine}
        </p>

        <NotifyModal
          locale={locale}
          copy={{
            notifyTitle: d.notifyTitle,
            notifyDescription: d.notifyDescription,
            notifyPlaceholder: d.notifyPlaceholder,
            notifySubmit: d.notifySubmit,
            notifySuccess: d.notifySuccess,
            notifyErrorInvalid: d.notifyErrorInvalid,
            notifyErrorSave: d.notifyErrorSave,
            notifyAlreadySubscribed: d.notifyAlreadySubscribed,
            notifyLegalHint: d.notifyLegalHint,
            notifyConsentLabel: d.notifyConsentLabel,
            notifyErrorConsent: d.notifyErrorConsent,
            notifyTriggerLabel: d.notifyTriggerLabel,
            notifyTriggerLoadingLabel: d.notifyTriggerLoadingLabel,
            notifySubscribedTriggerLabel: d.notifySubscribedTriggerLabel,
            notifyCloseLabel: d.notifyCloseLabel,
            notifyEmailLabel: d.notifyEmailLabel,
            notifySubmitPendingLabel: d.notifySubmitPendingLabel,
          }}
        />

        <footer className={styles.footer}>
          {d.footer} · {new Date().getFullYear()}
        </footer>
      </div>
    </main>
  );
}
