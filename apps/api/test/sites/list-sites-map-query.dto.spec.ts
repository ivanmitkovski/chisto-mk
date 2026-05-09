/// <reference types="jest" />

import { plainToInstance } from 'class-transformer';
import { validateSync } from 'class-validator';
import { ListSitesMapQueryDto } from '../../src/sites/dto/list-sites-map-query.dto';

describe('ListSitesMapQueryDto', () => {
  it('accepts fractional zoom values in valid range', () => {
    const dto = plainToInstance(ListSitesMapQueryDto, {
      lat: 41.9981,
      lng: 21.4254,
      radiusKm: 40,
      limit: 250,
      detail: 'lite',
      zoom: 11.4,
      minLat: 41.76,
      maxLat: 42.23,
      minLng: 21.23,
      maxLng: 21.61,
    });
    const errors = validateSync(dto, { forbidUnknownValues: false });
    expect(errors).toHaveLength(0);
  });

  it('accepts optional prefetch flag', () => {
    const dto = plainToInstance(ListSitesMapQueryDto, {
      lat: 41.9981,
      lng: 21.4254,
      prefetch: true,
    });
    const errors = validateSync(dto, { forbidUnknownValues: false });
    expect(errors).toHaveLength(0);
    expect(dto.prefetch).toBe(true);
  });

  it('rejects zoom outside allowed bounds', () => {
    const dto = plainToInstance(ListSitesMapQueryDto, {
      lat: 41.9981,
      lng: 21.4254,
      zoom: 22.5,
    });
    const errors = validateSync(dto, { forbidUnknownValues: false });
    expect(errors.length).toBeGreaterThan(0);
  });
});
