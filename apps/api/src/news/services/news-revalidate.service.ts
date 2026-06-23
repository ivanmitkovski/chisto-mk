import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class NewsRevalidateService {
  private readonly logger = new Logger(NewsRevalidateService.name);

  constructor(private readonly config: ConfigService) {}

  async triggerLandingRevalidate(): Promise<void> {
    const url = this.config.get<string>('LANDING_REVALIDATE_URL')?.trim();
    const secret = this.config.get<string>('LANDING_REVALIDATE_SECRET')?.trim();
    if (!url || !secret) {
      return;
    }
    try {
      const res = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${secret}`,
        },
        body: JSON.stringify({ tag: 'news' }),
      });
      if (!res.ok) {
        this.logger.warn(`landing revalidate failed status=${res.status}`);
      }
    } catch (err) {
      this.logger.warn(`landing revalidate error: ${(err as Error).message}`);
    }
  }
}
