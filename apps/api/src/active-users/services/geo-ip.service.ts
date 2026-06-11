import { Injectable, Logger } from '@nestjs/common';

export type GeoIpResult = {
  country: string | null;
  city: string | null;
};

/**
 * Coarse geo from IP. Uses ip-api.com free tier when configured; no-op for private/local IPs.
 * Never returns precise coordinates.
 */
@Injectable()
export class GeoIpService {
  private readonly logger = new Logger(GeoIpService.name);

  async lookup(ip: string | null | undefined): Promise<GeoIpResult> {
    const normalized = ip?.trim();
    if (!normalized || this.isPrivateIp(normalized)) {
      return { country: null, city: null };
    }
    if (process.env.GEOIP_ENABLED === 'false') {
      return { country: null, city: null };
    }
    try {
      const controller = new AbortController();
      const timer = setTimeout(() => controller.abort(), 2000);
      const response = await fetch(
        `http://ip-api.com/json/${encodeURIComponent(normalized)}?fields=status,country,city`,
        { signal: controller.signal },
      );
      clearTimeout(timer);
      if (!response.ok) {
        return { country: null, city: null };
      }
      const data = (await response.json()) as { status?: string; country?: string; city?: string };
      if (data.status !== 'success') {
        return { country: null, city: null };
      }
      return {
        country: data.country?.trim() || null,
        city: data.city?.trim() || null,
      };
    } catch (error) {
      this.logger.debug(`GeoIP lookup failed for ${normalized}: ${String(error)}`);
      return { country: null, city: null };
    }
  }

  private isPrivateIp(ip: string): boolean {
    if (ip === '127.0.0.1' || ip === '::1' || ip.startsWith('10.') || ip.startsWith('192.168.')) {
      return true;
    }
    if (ip.startsWith('172.')) {
      const second = Number.parseInt(ip.split('.')[1] ?? '0', 10);
      if (second >= 16 && second <= 31) return true;
    }
    return false;
  }
}
