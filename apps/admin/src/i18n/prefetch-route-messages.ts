'use client';

import { getRouteMessages } from './get-route-messages';
import { stageRouteMessages } from './route-message-cache';

export async function prefetchRouteMessages(pathname: string) {
  const messages = await getRouteMessages(pathname);
  stageRouteMessages(messages);
  return messages;
}
