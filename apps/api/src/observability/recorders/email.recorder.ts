import { emailOutboxDepth } from '../util/prom-registry';

let emailQueueDepth = 0;
let emailDeadLetterCount = 0;

export function setEmailQueueStats(input: { queueDepth: number; deadLetterCount: number }): void {
  emailQueueDepth = input.queueDepth;
  emailDeadLetterCount = input.deadLetterCount;
  emailOutboxDepth.set(emailQueueDepth);
}

export function snapshot() {
  return {
    emailQueueDepth,
    emailDeadLetterCount,
  };
}

export function resetForTests(): void {
  emailQueueDepth = 0;
  emailDeadLetterCount = 0;
  emailOutboxDepth.set(0);
}
