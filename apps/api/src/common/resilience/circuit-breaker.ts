import { Logger } from '@nestjs/common';

export enum CircuitState {
  CLOSED = 'CLOSED',
  OPEN = 'OPEN',
  HALF_OPEN = 'HALF_OPEN',
}

export interface CircuitBreakerOptions {
  name: string;
  failureThreshold?: number;
  resetTimeoutMs?: number;
  halfOpenMaxAttempts?: number;
}

const DEFAULT_FAILURE_THRESHOLD = 5;
const DEFAULT_RESET_TIMEOUT_MS = 30_000;
const DEFAULT_HALF_OPEN_MAX_ATTEMPTS = 2;

export class CircuitBreaker {
  private readonly logger: Logger;
  private state = CircuitState.CLOSED;
  private failureCount = 0;
  private lastFailureTime = 0;
  private halfOpenAttempts = 0;

  private readonly failureThreshold: number;
  private readonly resetTimeoutMs: number;
  private readonly halfOpenMaxAttempts: number;

  constructor(private readonly options: CircuitBreakerOptions) {
    this.logger = new Logger(`CircuitBreaker:${options.name}`);
    this.failureThreshold = options.failureThreshold ?? DEFAULT_FAILURE_THRESHOLD;
    this.resetTimeoutMs = options.resetTimeoutMs ?? DEFAULT_RESET_TIMEOUT_MS;
    this.halfOpenMaxAttempts = options.halfOpenMaxAttempts ?? DEFAULT_HALF_OPEN_MAX_ATTEMPTS;
  }

  get currentState(): CircuitState {
    if (this.state === CircuitState.OPEN && this.shouldAttemptReset()) {
      return CircuitState.HALF_OPEN;
    }
    return this.state;
  }

  async execute<T>(fn: () => Promise<T>): Promise<T> {
    const effectiveState = this.currentState;

    if (effectiveState === CircuitState.OPEN) {
      throw new CircuitBreakerOpenError(this.options.name, this.remainingCooldownMs());
    }

    if (effectiveState === CircuitState.HALF_OPEN) {
      this.state = CircuitState.HALF_OPEN;
      this.halfOpenAttempts += 1;
    }

    try {
      const result = await fn();
      this.onSuccess();
      return result;
    } catch (error) {
      this.onFailure();
      throw error;
    }
  }

  reset(): void {
    this.state = CircuitState.CLOSED;
    this.failureCount = 0;
    this.halfOpenAttempts = 0;
    this.lastFailureTime = 0;
  }

  getStats(): {
    name: string;
    state: CircuitState;
    failureCount: number;
    lastFailureTime: number;
  } {
    return {
      name: this.options.name,
      state: this.currentState,
      failureCount: this.failureCount,
      lastFailureTime: this.lastFailureTime,
    };
  }

  private onSuccess(): void {
    if (this.state === CircuitState.HALF_OPEN) {
      this.logger.log('Circuit recovered, transitioning to CLOSED');
    }
    this.reset();
  }

  private onFailure(): void {
    this.failureCount += 1;
    this.lastFailureTime = Date.now();

    if (this.state === CircuitState.HALF_OPEN) {
      if (this.halfOpenAttempts >= this.halfOpenMaxAttempts) {
        this.state = CircuitState.OPEN;
        this.logger.warn(
          `HALF_OPEN probe failed ${this.halfOpenAttempts} times, re-opening circuit`,
        );
      }
      return;
    }

    if (this.failureCount >= this.failureThreshold) {
      this.state = CircuitState.OPEN;
      this.logger.warn(
        `Failure threshold reached (${this.failureCount}/${this.failureThreshold}), opening circuit for ${this.resetTimeoutMs}ms`,
      );
    }
  }

  private shouldAttemptReset(): boolean {
    return Date.now() - this.lastFailureTime >= this.resetTimeoutMs;
  }

  private remainingCooldownMs(): number {
    const elapsed = Date.now() - this.lastFailureTime;
    return Math.max(0, this.resetTimeoutMs - elapsed);
  }
}

export class CircuitBreakerOpenError extends Error {
  readonly retryAfterMs: number;

  constructor(serviceName: string, retryAfterMs: number) {
    super(`Circuit breaker '${serviceName}' is OPEN. Retry after ${retryAfterMs}ms.`);
    this.name = 'CircuitBreakerOpenError';
    this.retryAfterMs = retryAfterMs;
  }
}
