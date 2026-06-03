import { stripCategoryLabelPrefix } from '../../src/reports/util/report-category-narrative';

describe('stripCategoryLabelPrefix', () => {
  it('returns empty string for null or empty input', () => {
    expect(stripCategoryLabelPrefix(null, 'OTHER')).toBe('');
    expect(stripCategoryLabelPrefix('', 'OTHER')).toBe('');
  });

  it('strips matching category label prefix case-insensitively', () => {
    expect(
      stripCategoryLabelPrefix('Illegal landfill: pile near road', 'ILLEGAL_LANDFILL'),
    ).toBe('pile near road');
    expect(
      stripCategoryLabelPrefix('illegal landfill:  debris', 'ILLEGAL_LANDFILL'),
    ).toBe('debris');
  });

  it('returns trimmed text when prefix does not match', () => {
    expect(stripCategoryLabelPrefix('  raw note  ', 'WATER_POLLUTION')).toBe('raw note');
  });

  it('returns trimmed text when category key is unknown', () => {
    expect(stripCategoryLabelPrefix('Illegal landfill: x', 'UNKNOWN')).toBe(
      'Illegal landfill: x',
    );
  });
});
