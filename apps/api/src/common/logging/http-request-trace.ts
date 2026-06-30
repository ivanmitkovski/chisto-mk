import { AsyncLocalStorage } from 'node:async_hooks';

type HttpRequestTraceStore = {
  traceparent?: string;
};

const store = new AsyncLocalStorage<HttpRequestTraceStore>();

export function runWithInboundTraceparent<T>(traceparent: string | undefined, fn: () => T): T {
  return store.run(traceparent ? { traceparent } : {}, fn);
}

export function getInboundTraceparent(): string | undefined {
  return store.getStore()?.traceparent;
}
