/// <reference types="jest" />
import 'reflect-metadata';
import { ReportsController } from '../../src/reports/reports.controller';

/** @nestjs/throttler v6 stores per-name keys as prefix + bucket name (e.g. `default`). */
const limitMetaKey = (name: string): string => `THROTTLER:LIMIT${name}`;
const ttlMetaKey = (name: string): string => `THROTTLER:TTL${name}`;
describe('ReportsController throttling metadata', () => {
  it('applies @Throttle to POST create, upload, append media', () => {
    const keys: Array<keyof ReportsController> = [
      'createWithLocation',
      'upload',
      'appendMedia',
    ];
    for (const key of keys) {
      const handler = ReportsController.prototype[key];
      expect(Reflect.getMetadata(limitMetaKey('default'), handler)).toBeDefined();
      expect(Reflect.getMetadata(ttlMetaKey('default'), handler)).toBeDefined();
    }
  });

  it('applies @Throttle to admin moderation and merge routes', () => {
    const keys: Array<keyof ReportsController> = [
      'findAllForModeration',
      'findDuplicateGroups',
      'findDuplicateGroupByReport',
      'updateStatus',
      'mergeDuplicates',
    ];
    for (const key of keys) {
      const handler = ReportsController.prototype[key];
      expect(Reflect.getMetadata(limitMetaKey('default'), handler)).toBeDefined();
      expect(Reflect.getMetadata(ttlMetaKey('default'), handler)).toBeDefined();
    }
  });
});
