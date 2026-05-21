import Link from 'next/link';
import { notFound } from 'next/navigation';
import { isLocale, type Locale } from '@/i18n/config';
import styles from '../../wip.module.css';

const COPY: Record<Locale, { title: string; intro: string; privacy: string }> = {
  mk: {
    title: 'Подобработувачи на податоци',
    intro: 'Трети страни кои обработуваат лични податоци во име на Chisto.mk.',
    privacy: 'Политика на приватност',
  },
  en: {
    title: 'Subprocessors',
    intro: 'Third-party services that process personal data on behalf of Chisto.mk.',
    privacy: 'Privacy policy',
  },
  sq: {
    title: 'Nënpërpunues',
    intro: 'Shërbime të palëve të treta që përpunojnë të dhëna personale për Chisto.mk.',
    privacy: 'Politika e privatësisë',
  },
  rom: {
    title: 'Subprocessors',
    intro: 'Third-party services processing personal data for Chisto.mk.',
    privacy: 'Privacy policy',
  },
  sr: {
    title: 'Подобрађивачи',
    intro: 'Треће стране које обрађују личне податке у име Chisto.mk.',
    privacy: 'Политика приватности',
  },
};

const subprocessors = [
  { name: 'Amazon Web Services', region: 'EU (Frankfurt)', purpose: 'Hosting, RDS, S3, ECS' },
  { name: 'Postmark', region: 'US', purpose: 'Transactional email' },
  { name: 'Twilio', region: 'US', purpose: 'SMS OTP' },
  { name: 'Google Firebase', region: 'EU/US', purpose: 'Push (FCM)' },
  { name: 'Sentry', region: 'EU', purpose: 'Error monitoring (scrubbed)' },
] as const;

type Props = { params: Promise<{ locale: string }> };

export default async function SubprocessorsPage({ params }: Props) {
  const { locale: raw } = await params;
  if (!isLocale(raw)) notFound();
  const c = COPY[raw];

  return (
    <main className={styles.page} style={{ maxWidth: 720, margin: '0 auto', padding: '2rem' }}>
      <h1>{c.title}</h1>
      <p>{c.intro}</p>
      <table style={{ width: '100%', borderCollapse: 'collapse' }}>
        <thead>
          <tr>
            <th align="left">Provider</th>
            <th align="left">Region</th>
            <th align="left">Purpose</th>
          </tr>
        </thead>
        <tbody>
          {subprocessors.map((row) => (
            <tr key={row.name}>
              <td>{row.name}</td>
              <td>{row.region}</td>
              <td>{row.purpose}</td>
            </tr>
          ))}
        </tbody>
      </table>
      <p style={{ marginTop: '2rem' }}>
        <Link href={`/${raw}`}>← Chisto.mk</Link>
        {' · '}
        <a href="https://chisto.mk/privacy">{c.privacy}</a>
      </p>
    </main>
  );
}
