export class ObservabilityStore {
  private static requestsTotal = 0;
  private static requestsFailed = 0;
  private static requestDurationsMs: number[] = [];

  static recordRequest(durationMs: number, statusCode: number): void {
    this.requestsTotal += 1;
    if (statusCode >= 500) {
      this.requestsFailed += 1;
    }
    this.requestDurationsMs.push(durationMs);
    if (this.requestDurationsMs.length > 2000) {
      this.requestDurationsMs = this.requestDurationsMs.slice(-1200);
    }
  }

  static snapshot() {
    const sorted = [...this.requestDurationsMs].sort((a, b) => a - b);
    const p = (percentile: number) => {
      if (sorted.length === 0) return 0;
      const idx = Math.min(sorted.length - 1, Math.floor((percentile / 100) * sorted.length));
      return Number(sorted[idx].toFixed(2));
    };
    return {
      requestsTotal: this.requestsTotal,
      requestsFailed: this.requestsFailed,
      p50Ms: p(50),
      p95Ms: p(95),
      p99Ms: p(99),
    };
  }
}
