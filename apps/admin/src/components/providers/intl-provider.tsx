'use client';

import { NextIntlClientProvider } from 'next-intl';
import { usePathname } from 'next/navigation';
import { type ReactNode, useLayoutEffect, useRef, useState } from 'react';
import { getRouteMessages } from '@/i18n/get-route-messages';
import { overlayStaticNewsMessages } from '@/i18n/static-news-messages';
import { consumeStagedRouteMessages } from '@/i18n/route-message-cache';
import { mergeRouteMessages, messagesSatisfyPathname } from '@/i18n/route-messages-client';

type IntlProviderProps = {
  locale: string;
  messages: Record<string, unknown>;
  timeZone?: string;
  children: ReactNode;
};

export function IntlProvider({
  locale,
  messages: initialMessages,
  timeZone = 'Europe/Skopje',
  children,
}: IntlProviderProps) {
  const pathname = usePathname();
  const messagesRef = useRef(initialMessages);
  const [messages, setMessages] = useState(() => overlayStaticNewsMessages(initialMessages, locale));
  const [messagesReady, setMessagesReady] = useState(() =>
    messagesSatisfyPathname(pathname, overlayStaticNewsMessages(initialMessages, locale)),
  );

  useLayoutEffect(() => {
    messagesRef.current = overlayStaticNewsMessages(initialMessages, locale);
    setMessages(messagesRef.current);
    setMessagesReady(messagesSatisfyPathname(pathname, messagesRef.current));
  }, [initialMessages, locale, pathname]);

  useLayoutEffect(() => {
    let cancelled = false;
    const staged = consumeStagedRouteMessages();
    let merged = overlayStaticNewsMessages(
      staged ? mergeRouteMessages(staged, initialMessages) : initialMessages,
      locale,
    );

    if (messagesSatisfyPathname(pathname, merged)) {
      messagesRef.current = merged;
      setMessages(merged);
      setMessagesReady(true);
      return undefined;
    }

    messagesRef.current = merged;
    setMessages(merged);
    setMessagesReady(false);

    void getRouteMessages(pathname).then((nextMessages) => {
      if (cancelled) return;
      merged = overlayStaticNewsMessages(mergeRouteMessages(merged, nextMessages), locale);
      messagesRef.current = merged;
      setMessages(merged);
      setMessagesReady(true);
    });

    return () => {
      cancelled = true;
    };
  }, [initialMessages, locale, pathname]);

  if (!messagesReady) {
    return null;
  }

  return (
    <NextIntlClientProvider locale={locale} messages={messages} timeZone={timeZone}>
      {children}
    </NextIntlClientProvider>
  );
}
