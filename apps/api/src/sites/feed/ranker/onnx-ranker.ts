import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createHash } from 'crypto';
import { RankerProvider } from './ranker.provider';
import { FeatureVectorV1 } from '../features/feature-vector.types';
import { ModelRegistryClient } from './model-registry.client';
import { RulesFallbackRanker } from './rules-fallback-ranker';
import { ObservabilityStore } from '../../../observability/observability.store';

type OrtModule = typeof import('onnxruntime-node');

@Injectable()
export class OnnxRanker implements RankerProvider {
  private readonly logger = new Logger(OnnxRanker.name);
  private currentVersion = 'unloaded';
  private ortModule: OrtModule | null = null;
  private session: import('onnxruntime-node').InferenceSession | null = null;

  constructor(
    private readonly config: ConfigService,
    private readonly registry: ModelRegistryClient,
    private readonly fallback: RulesFallbackRanker,
  ) {}

  async score(features: FeatureVectorV1[]): Promise<number[]> {
    const enabled = this.config.get<string>('FEED_V2_ONNX_ENABLED') === 'true';
    if (!enabled) {
      ObservabilityStore.setFeedV2RankerMode('rules_fallback_disabled');
      return this.fallback.score(features);
    }
    try {
      const ort = await this.getOrtModule();
      if (!ort) {
        ObservabilityStore.setFeedV2RankerMode('onnx_unavailable');
        return this.fallback.score(features);
      }
      await this.ensureSessionLoaded();
      if (!this.session) {
        ObservabilityStore.setFeedV2RankerMode('rules_fallback_no_model');
        return this.fallback.score(features);
      }
      const inputName = this.session.inputNames[0];
      const outputName = this.session.outputNames[0];
      if (!inputName || !outputName) {
        throw new Error('ONNX model has no expected IO names');
      }
      const vectorLen = 11;
      const values = features.flatMap((f) => [
        f.engagementVelocity24h,
        f.engagementIntensity,
        f.freshnessHours,
        f.distanceKm,
        f.statusTrust,
        f.severityIndex,
        f.discussionRatio,
        f.intentRatio,
        f.reportCount,
        f.wasSeenRecently,
        f.followsReporter,
      ]);
      const tensor = new ort.Tensor('float32', Float32Array.from(values), [features.length, vectorLen]);
      const results = await this.session.run({ [inputName]: tensor });
      const output = results[outputName];
      if (!output || !Array.isArray(output.data)) {
        throw new Error('ONNX model output missing');
      }
      ObservabilityStore.setFeedV2RankerMode('onnx_loaded');
      return Array.from(output.data as ArrayLike<unknown>).map((v: unknown) => Number(v));
    } catch (error) {
      this.logger.warn(`ONNX scoring failed, falling back to rules ranker: ${String(error)}`);
      this.session = null;
      this.currentVersion = this.fallback.modelVersion();
      ObservabilityStore.setFeedV2RankerMode('rules_fallback_error');
      return this.fallback.score(features);
    }
  }

  modelVersion(): string {
    return this.currentVersion === 'unloaded' ? this.fallback.modelVersion() : this.currentVersion;
  }

  private async ensureSessionLoaded(): Promise<void> {
    const ort = await this.getOrtModule();
    if (!ort) {
      this.session = null;
      this.currentVersion = this.fallback.modelVersion();
      return;
    }
    const manifest = await this.registry.latestManifest();
    if (!manifest) {
      this.session = null;
      this.currentVersion = this.fallback.modelVersion();
      return;
    }
    if (this.session && this.currentVersion === manifest.version) return;
    const modelBuffer = await this.registry.downloadModel(manifest);
    const checksum = createHash('sha256').update(modelBuffer).digest('hex');
    if (manifest.sha256.trim().length > 0 && checksum !== manifest.sha256.trim().toLowerCase()) {
      throw new Error(`Feed model checksum mismatch for ${manifest.version}`);
    }
    this.session = await ort.InferenceSession.create(modelBuffer, {
      executionProviders: ['cpu'],
      graphOptimizationLevel: 'all',
    });
    this.currentVersion = manifest.version;
    this.logger.log(`Feed ONNX model loaded: ${manifest.version}`);
  }

  private async getOrtModule(): Promise<OrtModule | null> {
    if (this.ortModule) return this.ortModule;
    try {
      const ort = await import('onnxruntime-node');
      this.ortModule = ort;
      return ort;
    } catch (error) {
      this.logger.warn(
        `onnxruntime-node unavailable, using fallback ranker: ${
          error instanceof Error ? error.message : String(error)
        }`,
      );
      return null;
    }
  }
}
