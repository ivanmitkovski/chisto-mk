import Link from 'next/link';
import { AdminShell } from '@/features/admin-shell';
import styles from './not-found.module.css';

export default function DashboardNotFound() {
  return (
    <AdminShell title="Not found" activeItem="dashboard">
      <main className={styles.main}>
        <section className={styles.card}>
          <h2 className={styles.title}>
            This page doesn&apos;t exist
          </h2>
          <p className={styles.message}>
            The dashboard route you&apos;re looking for was not found.
          </p>
          <Link href="/dashboard" className={styles.link}>
            Go to Overview
          </Link>
        </section>
      </main>
    </AdminShell>
  );
}
