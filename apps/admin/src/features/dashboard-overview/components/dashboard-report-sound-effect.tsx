'use client';

import { usePathname } from 'next/navigation';
import { NewReportSoundEffect } from './new-report-sound-effect';

function isReportsSoundRoute(pathname: string): boolean {
  return pathname === '/dashboard' || pathname.startsWith('/dashboard/reports');
}

export function DashboardReportSoundEffect() {
  const pathname = usePathname();
  if (!isReportsSoundRoute(pathname)) {
    return null;
  }
  return <NewReportSoundEffect />;
}
