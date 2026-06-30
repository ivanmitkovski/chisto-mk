import { Injectable } from '@nestjs/common';
import { ObservabilityStore } from '../../observability/observability.store';

@Injectable()
export class MapObservabilityService {
  recordRequest(input: {
    durationMs: number;
    candidatePoolSize: number;
    cacheHit: boolean;
    servedFromFallback?: boolean;
    mode?: 'sites' | 'clusters' | 'heatmap';
    zoomBucket?: 'z_le_8' | 'z_9_12' | 'z_ge_13';
  }): void {
    ObservabilityStore.recordMapRequest(input);
    ObservabilityStore.recordMapQueryRowCount(input.candidatePoolSize);
  }

  recordZoomTier(tier: 'low' | 'mid' | 'high'): void {
    ObservabilityStore.recordMapZoomTierRequest(tier);
  }
}
