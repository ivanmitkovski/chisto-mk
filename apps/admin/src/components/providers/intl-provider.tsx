'use client';

import { NextIntlClientProvider } from 'next-intl';
import type { ReactNode } from 'react';

type IntlProviderProps = {
  locale: string;
  messages: Record<string, unknown>;
  timeZone?: string;
  children: ReactNode;
};

export function IntlProvider({ locale, messages, timeZone = 'Europe/Skopje', children }: IntlProviderProps) {
  return (
    <NextIntlClientProvider locale={locale} messages={messages} timeZone={timeZone}>
      {children}
    </NextIntlClientProvider>
  );
}
