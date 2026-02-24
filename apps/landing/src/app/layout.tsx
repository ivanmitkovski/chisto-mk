import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'Chisto.mk — Civic Environmental Platform',
  description:
    'Report pollution, join cleanup events, and make North Macedonia cleaner. Together we can make a difference.',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
