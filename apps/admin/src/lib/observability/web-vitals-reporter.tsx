'use client';

import { useEffect } from 'react';
import { usePathname } from 'next/navigation';
import { onCLS, onINP, onLCP, type Metric } from 'web-vitals';
import { clientLogger } from './client-logger';

function reportWebVital(metric: Metric, pathname: string): void {
  clientLogger.info('web_vital', {
    name: metric.name,
    value: Math.round(metric.name === 'CLS' ? metric.value * 1000 : metric.value),
    rating: metric.rating,
    route: pathname,
    id: metric.id,
    navigationType: metric.navigationType,
  });
}

export function WebVitalsReporter() {
  const pathname = usePathname();

  useEffect(() => {
    const route = pathname ?? '/';
    const report = (metric: Metric) => reportWebVital(metric, route);

    onLCP(report);
    onINP(report);
    onCLS(report);
  }, [pathname]);

  return null;
}
