import { Injectable } from '@nestjs/common';
import { WorkerHeartbeatRegistry } from '../../observability/worker-heartbeat.registry';
import { EmailSendEligibilityService } from './email-send-eligibility.service';
import { PrismaService } from '../../prisma/prisma.service';

const EMAIL_WORKER_NAME = 'email-delivery';
const QUEUE_DEPTH_WARN = 10;
const QUEUE_DEPTH_CRITICAL = 50;
const DEAD_LETTER_WARN = 1;

export type EmailPipelineHealthSnapshot = {
  status: 'ok' | 'degraded' | 'disabled';
  emailEnabled: boolean;
  worker: {
    expected: boolean;
    running: boolean;
    stale: boolean;
    lastError?: string;
  };
  outbox: {
    pending: number;
    deadLetter: number;
  };
  alerts: string[];
};

@Injectable()
export class EmailPipelineHealthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly emailEligibility: EmailSendEligibilityService,
  ) {}

  async getHealthSnapshot(): Promise<EmailPipelineHealthSnapshot> {
    const emailEnabled = await this.emailEligibility.isGloballyEnabled();
    const workerSnap = WorkerHeartbeatRegistry.snapshot().find((w) => w.name === EMAIL_WORKER_NAME);
    const workerExpected = emailEnabled;
    const workerRunning = workerSnap?.running ?? false;
    const workerStale = workerExpected && (workerSnap == null || workerSnap.stale);

    const [pending, deadLetter] = await Promise.all([
      this.prisma.emailOutbox.count({
        where: {
          deliveredAt: null,
          failedPermanently: false,
        },
      }),
      this.prisma.emailOutbox.count({
        where: { failedPermanently: true },
      }),
    ]);

    const alerts: string[] = [];
    if (!emailEnabled) {
      return {
        status: 'disabled',
        emailEnabled,
        worker: {
          expected: workerExpected,
          running: workerRunning,
          stale: workerStale,
          ...(workerSnap?.lastError ? { lastError: workerSnap.lastError } : {}),
        },
        outbox: {
          pending,
          deadLetter,
        },
        alerts,
      };
    }

    if (workerStale) {
      alerts.push('email_worker_stale');
    }
    const queueDepth = pending;
    const dlqCount = deadLetter;
    if (queueDepth >= QUEUE_DEPTH_CRITICAL) {
      alerts.push(`email_queue_depth_critical:${queueDepth}`);
    } else if (queueDepth >= QUEUE_DEPTH_WARN) {
      alerts.push(`email_queue_depth_high:${queueDepth}`);
    }
    if (dlqCount >= DEAD_LETTER_WARN) {
      alerts.push(`email_dead_letter_total:${dlqCount}`);
    }

    return {
      status: alerts.length > 0 ? 'degraded' : 'ok',
      emailEnabled,
      worker: {
        expected: workerExpected,
        running: workerRunning,
        stale: workerStale,
        ...(workerSnap?.lastError ? { lastError: workerSnap.lastError } : {}),
      },
      outbox: { pending: queueDepth, deadLetter: dlqCount },
      alerts,
    };
  }
}
