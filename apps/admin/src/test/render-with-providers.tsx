import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { render, type RenderOptions, type RenderResult } from '@testing-library/react';
import { NextIntlClientProvider } from 'next-intl';
import type { ReactElement, ReactNode } from 'react';
import { ToastProvider } from '@/components/ui';

import enBroadcasts from '@/i18n/messages/en/broadcasts.json';
import enCommon from '@/i18n/messages/en/common.json';
import enErrors from '@/i18n/messages/en/errors.json';
import enNav from '@/i18n/messages/en/nav.json';
import enReports from '@/i18n/messages/en/reports.json';
import enUi from '@/i18n/messages/en/ui.json';

const messages = {
  broadcasts: enBroadcasts,
  common: enCommon,
  errors: enErrors,
  nav: enNav,
  reports: enReports,
  ui: enUi,
};

type ProviderProps = {
  children: ReactNode;
};

function TestProviders({ children }: ProviderProps) {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: { retry: false },
      mutations: { retry: false },
    },
  });

  return (
    <NextIntlClientProvider locale="en" messages={messages}>
      <QueryClientProvider client={queryClient}>
        <ToastProvider>{children}</ToastProvider>
      </QueryClientProvider>
    </NextIntlClientProvider>
  );
}

export function renderWithProviders(
  ui: ReactElement,
  options?: Omit<RenderOptions, 'wrapper'>,
): RenderResult {
  return render(ui, { wrapper: TestProviders, ...options });
}
