import { legacySnapshotGauges } from '../util/prom-registry';

let pushSendsTotal = 0;
let pushSendsSuccess = 0;
let pushSendsFailure = 0;
let pushSendsRevoked = 0;
let pushTokenRevocations = 0;
let pushQueueRetries = 0;
let pushInboxReads = 0;
let pushQueueDepth = 0;
let pushActiveLeases = 0;
let pushDeadLetterCount = 0;
let pushSendsByType: Record<string, { success: number; failure: number; revoked: number }> = {};

export function recordPushSend(
  outcome: 'success' | 'failure' | 'revoked',
  notificationType?: string,
): void {
  pushSendsTotal += 1;
  if (outcome === 'success') pushSendsSuccess += 1;
  else if (outcome === 'failure') pushSendsFailure += 1;
  else if (outcome === 'revoked') pushSendsRevoked += 1;

  if (notificationType) {
    const bucket = pushSendsByType[notificationType] ?? { success: 0, failure: 0, revoked: 0 };
    bucket[outcome] += 1;
    pushSendsByType[notificationType] = bucket;
  }
}

export function getPushSendsByType(): Record<
  string,
  { success: number; failure: number; revoked: number }
> {
  return { ...pushSendsByType };
}

export function recordPushTokenRevocation(): void {
  pushTokenRevocations += 1;
}

export function recordPushQueueRetry(): void {
  pushQueueRetries += 1;
}

export function recordPushInboxRead(): void {
  pushInboxReads += 1;
}

export function setPushQueueStats(input: {
  queueDepth: number;
  activeLeases: number;
  deadLetterCount: number;
}): void {
  pushQueueDepth = input.queueDepth;
  pushActiveLeases = input.activeLeases;
  pushDeadLetterCount = input.deadLetterCount;
  legacySnapshotGauges.pushDeadLetter.set(pushDeadLetterCount);
}

export function snapshot() {
  return {
    pushSendsTotal,
    pushSendsSuccess,
    pushSendsFailure,
    pushSendsRevoked,
    pushSendsByType: getPushSendsByType(),
    pushTokenRevocations,
    pushQueueRetries,
    pushInboxReads,
    pushQueueDepth,
    pushActiveLeases,
    pushDeadLetterCount,
  };
}
