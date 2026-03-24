import Link from 'next/link';
import { AdminShell } from '@/features/admin-shell';

export default function DashboardNotFound() {
  return (
    <AdminShell title="Not found" activeItem="dashboard">
      <main
        style={{
          minHeight: '50vh',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          padding: 'var(--space-7)',
        }}
      >
        <section
          style={{
            maxWidth: '24rem',
            padding: 'var(--space-6)',
            background: 'var(--bg-surface)',
            borderRadius: 'var(--radius-card)',
            boxShadow: 'var(--shadow-sm)',
            textAlign: 'center',
          }}
        >
          <h2
            style={{
              margin: '0 0 var(--space-2)',
              fontSize: 'var(--font-size-xl)',
              fontWeight: 'var(--font-weight-bold)',
            }}
          >
            This page doesn&apos;t exist
          </h2>
          <p
            style={{
              margin: '0 0 var(--space-5)',
              color: 'var(--text-secondary)',
              fontSize: 'var(--font-size-base)',
            }}
          >
            The dashboard route you&apos;re looking for was not found.
          </p>
          <Link
            href="/dashboard"
            style={{
              display: 'inline-flex',
              alignItems: 'center',
              justifyContent: 'center',
              padding: 'var(--space-2) var(--space-4)',
              background: 'var(--color-primary)',
              color: 'var(--color-green-900)',
              borderRadius: 'var(--radius-full)',
              fontSize: 'var(--font-size-base)',
              fontWeight: 'var(--font-weight-semibold)',
              textDecoration: 'none',
            }}
          >
            Go to Overview
          </Link>
        </section>
      </main>
    </AdminShell>
  );
}
