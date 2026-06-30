import { reportLocaleFromAcceptLanguage } from '../../src/reports/util/report-locale.util';

describe('reportLocaleFromAcceptLanguage', () => {
  it('defaults to mk when header is undefined', () => {
    expect(reportLocaleFromAcceptLanguage(undefined)).toBe('mk');
  });

  it('parses sq from Accept-Language', () => {
    expect(reportLocaleFromAcceptLanguage('sq-AL,en;q=0.9')).toBe('sq');
  });

  it('parses en from Accept-Language', () => {
    expect(reportLocaleFromAcceptLanguage('en-US,en;q=0.8')).toBe('en');
  });

  it('uses first language tag when header is an array', () => {
    expect(reportLocaleFromAcceptLanguage(['mk-MK', 'en'])).toBe('mk');
  });

  it('falls back to mk for unsupported primary tag', () => {
    expect(reportLocaleFromAcceptLanguage('de-DE')).toBe('mk');
  });
});
