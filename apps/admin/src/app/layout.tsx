import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'Chisto.mk Admin',
  description: 'Admin panel for Chisto.mk civic environmental platform',
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
