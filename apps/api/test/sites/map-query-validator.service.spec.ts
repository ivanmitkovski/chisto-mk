/// <reference types="jest" />

import { BadRequestException } from '@nestjs/common';
import { MapQueryValidatorService } from '../../src/sites/map/map-query-validator.service';

describe('MapQueryValidatorService', () => {
  it('throws when only partial viewport bounds are provided', () => {
    const service = new MapQueryValidatorService();
    expect(() =>
      service.validateQuery({
        lat: 41.6,
        lng: 21.7,
        radiusKm: 10,
        limit: 100,
        minLat: 41.0,
      } as any),
    ).toThrow(BadRequestException);
  });

  it('throws when viewport span is too wide', () => {
    const service = new MapQueryValidatorService();
    expect(() =>
      service.validateQuery({
        lat: 41.6,
        lng: 21.7,
        radiusKm: 10,
        limit: 100,
        minLat: 39,
        maxLat: 44,
        minLng: 20,
        maxLng: 24.5,
      } as any),
    ).toThrow(BadRequestException);
  });

  it('accepts complete, bounded viewport', () => {
    const service = new MapQueryValidatorService();
    expect(() =>
      service.validateQuery({
        lat: 41.6,
        lng: 21.7,
        radiusKm: 10,
        limit: 100,
        minLat: 41.2,
        maxLat: 41.9,
        minLng: 21.2,
        maxLng: 22.0,
      } as any),
    ).not.toThrow();
  });
});
