import 'server-only';

import { redirect } from 'next/navigation';
import { getTranslations } from 'next-intl/server';
import { ApiConnectionError, ApiError } from '@/lib/api';

type ErrorsNamespaceKey =
  | 'unableToLoadUsers'
  | 'unableToLoadGamification'
  | 'unableToLoadRiskSignals'
  | 'unableToLoadSites'
  | 'unableToLoadTeam'
  | 'unableToLoadEvent'
  | 'unableToLoadSettings'
  | 'unableToLoadEmailSuppressions'
  | 'unableToLoadSite'
  | 'unableToLoadBroadcasts'
  | 'unableToLoadNews'
  | 'unableToLoadWebhookLogs'
  | 'unableToLoadAudit'
  | 'unableToLoadUser'
  | 'unableToLoadAppConfig'
  | 'unableToLoadEvents'
  | 'unableToLoadReports'
  | 'unableToLoadReport'
  | 'unableToLoadDuplicates'
  | 'unableToLoadUgcReports'
  | 'unableToLoadNotifications'
  | 'unableToLoadActiveUsers'
  | 'unableToLoadResolutions'
  | 'unableToLoadDeclineReason'
  | 'unableToLoadModerationEmailPrefs'
  | 'apiConnectionFailed'
  | 'somethingWentWrongTryAgain';

type HandleServerLoadErrorOptions = {
  fallbackMessageKey?: ErrorsNamespaceKey;
};

/**
 * Normalizes RSC data-load failures: auth errors redirect to login;
 * connection errors return a localized message; other errors rethrow or use fallback.
 */
export async function handleServerLoadError(
  error: unknown,
  options: HandleServerLoadErrorOptions = {},
): Promise<string> {
  if (error instanceof ApiError && (error.status === 401 || error.status === 403)) {
    redirect('/login');
  }

  const t = await getTranslations('errors');

  if (error instanceof ApiConnectionError) {
    return t('apiConnectionFailed');
  }

  if (options.fallbackMessageKey) {
    return t(options.fallbackMessageKey);
  }

  throw error;
}
