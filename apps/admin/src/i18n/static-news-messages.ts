import type { AdminLocale } from '@/lib/preferences/admin-locale';
import enNews from './messages/en/news.json';
import mkNews from './messages/mk/news.json';
import sqNews from './messages/sq/news.json';

const NEWS_MESSAGES: Record<AdminLocale, typeof enNews> = {
  en: enNews,
  mk: mkNews,
  sq: sqNews,
};

/** Static news bundle — avoids stale dynamic-import caches during dev HMR. */
export function getStaticNewsMessages(locale: string): typeof enNews {
  const key = locale as AdminLocale;
  return NEWS_MESSAGES[key] ?? enNews;
}

export function overlayStaticNewsMessages(
  messages: Record<string, unknown>,
  locale: string,
): Record<string, unknown> {
  return { ...messages, news: getStaticNewsMessages(locale) };
}
