import type { Request } from 'express';
import { clientIp } from '../../src/sites/http/client-ip';
import { weakEtagForMapBody } from '../../src/sites/http/map-etag';
import {
  normalizeShareClickEvent,
  normalizeShareOpenEvent,
} from '../../src/sites/http/share-attribution-normalizer';

describe('Sites HTTP helpers', () => {
  describe('clientIp', () => {
    it('prefers req.ip when present', () => {
      const req = { ip: '10.0.0.4' } as Request;
      expect(clientIp(req, '1.1.1.1, 2.2.2.2')).toBe('10.0.0.4');
    });

    it('falls back to first x-forwarded-for entry', () => {
      const req = { ip: '' } as Request;
      expect(clientIp(req, '1.1.1.1, 2.2.2.2')).toBe('1.1.1.1');
    });
  });

  describe('weakEtagForMapBody', () => {
    it('generates deterministic weak etag from ids and updatedAt', () => {
      const body = {
        data: [
          { id: 'cabc123', updatedAt: '2026-01-01T00:00:00.000Z' },
          { id: 'cabc124', updatedAt: '2026-01-01T00:00:01.000Z' },
        ],
      };
      const first = weakEtagForMapBody(body);
      const second = weakEtagForMapBody(body);
      expect(first).toBe(second);
      expect(first.startsWith('W/"')).toBe(true);
    });
  });

  describe('share attribution normalization', () => {
    it('forces CLICK + WEB for click ingestion', () => {
      const normalized = normalizeShareClickEvent({
        token: 't',
        eventType: 'OPEN',
        source: 'APP',
      });
      expect(normalized.eventType).toBe('CLICK');
      expect(normalized.source).toBe('WEB');
    });

    it('forces OPEN + APP for open ingestion', () => {
      const normalized = normalizeShareOpenEvent({
        token: 't',
        eventType: 'CLICK',
        source: 'WEB',
      });
      expect(normalized.eventType).toBe('OPEN');
      expect(normalized.source).toBe('APP');
    });
  });
});
