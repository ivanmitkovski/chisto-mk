export type WorkerHeartbeatInput = {
  name: string;
  intervalMs: number;
};

export type WorkerHeartbeatRecordInput = {
  ok: boolean;
  error?: string;
};

export type WorkerHeartbeatSnapshot = {
  name: string;
  running: boolean;
  intervalMs: number;
  startedAt: string;
  lastRunAt: string | null;
  lastSuccessAt: string | null;
  lastError: string | null;
  stale: boolean;
};

type WorkerState = {
  name: string;
  intervalMs: number;
  startedAt: string;
  lastRunAt: string | null;
  lastSuccessAt: string | null;
  lastError: string | null;
  running: boolean;
};

class WorkerHeartbeatRegistryImpl {
  private readonly workers = new Map<string, WorkerState>();

  markStarted(input: WorkerHeartbeatInput): void {
    const existing = this.workers.get(input.name);
    if (existing) {
      existing.intervalMs = input.intervalMs;
      existing.running = true;
      return;
    }
    this.workers.set(input.name, {
      name: input.name,
      intervalMs: input.intervalMs,
      startedAt: new Date().toISOString(),
      lastRunAt: null,
      lastSuccessAt: null,
      lastError: null,
      running: true,
    });
  }

  markStopped(name: string): void {
    const worker = this.workers.get(name);
    if (worker) {
      worker.running = false;
    }
  }

  record(name: string, result: WorkerHeartbeatRecordInput): void {
    const worker = this.workers.get(name);
    if (!worker) {
      return;
    }
    const now = new Date().toISOString();
    worker.lastRunAt = now;
    if (result.ok) {
      worker.lastSuccessAt = now;
      worker.lastError = null;
    } else {
      worker.lastError = result.error?.slice(0, 500) ?? 'Unknown error';
    }
  }

  snapshot(): WorkerHeartbeatSnapshot[] {
    const now = Date.now();
    return [...this.workers.values()].map((worker) => {
      const lastRunMs = worker.lastRunAt ? Date.parse(worker.lastRunAt) : null;
      const staleThresholdMs = worker.intervalMs * 2;
      const stale =
        !worker.running ||
        lastRunMs == null ||
        now - lastRunMs > staleThresholdMs;
      return {
        name: worker.name,
        running: worker.running,
        intervalMs: worker.intervalMs,
        startedAt: worker.startedAt,
        lastRunAt: worker.lastRunAt,
        lastSuccessAt: worker.lastSuccessAt,
        lastError: worker.lastError,
        stale,
      };
    });
  }

  resetForTests(): void {
    this.workers.clear();
  }
}

export const WorkerHeartbeatRegistry = new WorkerHeartbeatRegistryImpl();
