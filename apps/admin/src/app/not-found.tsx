import Image from 'next/image';
import Link from 'next/link';
import { getTranslations } from 'next-intl/server';
import styles from './not-found.module.css';

export default async function NotFound() {
  const t = await getTranslations('common');

  return (
    <main className={styles.wrapper}>
      <div className={styles.content}>
        {/* Default loading is lazy; no priority — 404 is not a primary LCP path. */}
        <Image
          src="/images/404.svg"
          alt=""
          width={232}
          height={109}
          className={styles.illustration}
          sizes="(max-width: 480px) 100vw, 232px"
        />
        <h1 className={styles.title}>{t('pageNotFound')}</h1>
        <p className={styles.subtitle}>{t('pageNotFoundDescription')}</p>
        <div className={styles.actions}>
          <Link href="/login" className={styles.primary}>
            {t('backToLogin')}
          </Link>
          <Link href="/dashboard" className={styles.secondary}>
            {t('goToDashboard')}
          </Link>
        </div>
      </div>
    </main>
  );
}
