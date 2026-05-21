const DEFAULT_TIMEOUT_MS = 5_000;

export async function fetchWithTimeout(
  input: string | URL,
  init: RequestInit & { timeoutMs?: number } = {},
): Promise<Response> {
  const { timeoutMs = DEFAULT_TIMEOUT_MS, ...rest } = init;
  return fetch(input, {
    ...rest,
    signal: rest.signal ?? AbortSignal.timeout(timeoutMs),
  });
}
