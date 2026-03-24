import type { Metadata, Viewport } from 'next';
import { Roboto } from 'next/font/google';
import { QueryProvider } from '@/components/providers/query-provider';
import './globals.css';

const roboto = Roboto({
  subsets: ['latin', 'cyrillic'],
  display: 'swap',
  variable: '--font-roboto',
  weight: ['400', '500', '700'],
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

export const metadata: Metadata = {
  metadataBase: resolveMetadataBase(),
  title: {
    default: 'Chisto Admin',
    template: '%s · Chisto Admin',
  },
  description: 'Admin panel for Chisto.mk civic environmental platform',
  applicationName: 'Chisto Admin',
  robots: {
    index: false,
    follow: false,
    googleBot: { index: false, follow: false },
  },
  openGraph: {
    type: 'website',
    siteName: 'Chisto.mk Admin',
    locale: 'en_US',
    title: 'Chisto.mk Admin',
    description: 'Admin panel for Chisto.mk civic environmental platform',
  },
};

export const viewport: Viewport = {
  themeColor: '#f7f8fe',
  width: 'device-width',
  initialScale: 1,
  viewportFit: 'cover',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className={roboto.variable}>
      <body className={roboto.className}>
        <QueryProvider>{children}</QueryProvider>
      </body>
    </html>
  );
}
