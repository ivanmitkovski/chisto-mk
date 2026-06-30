import { FeatureVectorV1 } from '../features/feature-vector.types';

export interface RankerProvider {
  score(features: FeatureVectorV1[]): Promise<number[]>;
  modelVersion(): string;
}
