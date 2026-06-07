import type { Metadata, Viewport } from 'next';
import { cookies } from 'next/headers';
import { getLocale, getMessages, getTranslations } from 'next-intl/server';
import { Roboto } from 'next/font/google';
import '@/lib/utils/server-dns-init';
import { IntlProvider } from '@/components/providers/intl-provider';
import { LocaleSync } from '@/components/providers/locale-sync';
import { MotionProvider } from '@/components/providers/motion-provider';
import { ReducedMotionSync } from '@/components/providers/reduced-motion-sync';
import { QueryProvider } from '@/components/providers/query-provider';
import { ToastProvider } from '@/components/ui';
import { GlobalErrorReporter } from '@/lib/observability';
import {
  ADMIN_LOCALE_OPEN_GRAPH,
  isAdminLocale,
  type AdminLocale,
} from '@/lib/preferences/admin-locale';
import {
  ADMIN_REDUCED_MOTION_CLASS,
  ADMIN_REDUCED_MOTION_COOKIE,
} from '@/lib/preferences/admin-preferences';
import './globals.css';

const roboto = Roboto({
  subsets: ['latin', 'cyrillic'],
  display: 'swap',
  variable: '--font-roboto',
  weight: ['400', '500', '700'],
  adjustFontFallback: true,
});

function resolveMetadataBase(): URL {
  const raw = process.env.NEXT_PUBLIC_ADMIN_SITE_URL?.trim();
  if (raw) {
    try {
      return new URL(raw.endsWith('/') ? raw.slice(0, -1) : raw);
    } catch {
      // fall through
    }
  }
  return new URL('http://localhost:3001');
}

export async function generateMetadata(): Promise<Metadata> {
  const locale = await getLocale();
  const t = await getTranslations({ locale, namespace: 'common' });
  const ogLocale = isAdminLocale(locale) ? ADMIN_LOCALE_OPEN_GRAPH[locale] : ADMIN_LOCALE_OPEN_GRAPH.en;

  return {
    metadataBase: resolveMetadataBase(),
    title: {
      default: t('appName'),
      template: `%s · ${t('appName')}`,
    },
    description: t('appDescription'),
    applicationName: t('appName'),
    robots: {
      index: false,
      follow: false,
      googleBot: { index: false, follow: false },
    },
    openGraph: {
      type: 'website',
      siteName: t('appName'),
      locale: ogLocale,
      title: t('appName'),
      description: t('appDescription'),
    },
  };
}

export const viewport: Viewport = {
  themeColor: '#f7f8fe',
  width: 'device-width',
  initialScale: 1,
  viewportFit: 'cover',
};

/** Required for per-request CSP nonces on routes outside `dashboard` (e.g. `/login`). */
export const dynamic = 'force-dynamic';

export default async function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const cookieStore = await cookies();
  const serverReducedMotion = cookieStore.get(ADMIN_REDUCED_MOTION_COOKIE)?.value === '1';
  const locale = (await getLocale()) as AdminLocale;
  const messages = await getMessages();
  const htmlClassName = [roboto.variable, serverReducedMotion ? ADMIN_REDUCED_MOTION_CLASS : '']
    .filter(Boolean)
    .join(' ');

  return (
    <html lang={locale} className={htmlClassName} suppressHydrationWarning>
      <body className={roboto.className}>
        <LocaleSync serverLocale={locale} />
        <GlobalErrorReporter />
        <ReducedMotionSync serverReducedMotion={serverReducedMotion} />
        <IntlProvider locale={locale} messages={messages}>
          <MotionProvider>
            <QueryProvider>
              <ToastProvider>{children}</ToastProvider>
            </QueryProvider>
          </MotionProvider>
        </IntlProvider>
      </body>
    </html>
  );
}
