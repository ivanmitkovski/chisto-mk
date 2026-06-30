/** Sampled warn logging for high-volume 4xx paths (default 10% in production). */
export function shouldSampleClientErrorLog(): boolean {
  if (process.env.NODE_ENV !== 'production') {
    return true;
  }
  const rate = Number(process.env.CLIENT_ERROR_LOG_SAMPLE_RATE ?? 0.1);
  if (!Number.isFinite(rate) || rate >= 1) {
    return true;
  }
  if (rate <= 0) {
    return false;
  }
  return Math.random() < rate;
}
