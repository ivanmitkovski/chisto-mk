import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import Typesense from 'typesense';
import type Client from 'typesense/lib/Typesense/Client';
import { loadTypesenseConfig, type TypesenseConfig } from './typesense.config';

@Injectable()
export class TypesenseClientService implements OnModuleInit {
  private readonly logger = new Logger(TypesenseClientService.name);
  private client: Client | null = null;
  private cfg: TypesenseConfig = loadTypesenseConfig();

  onModuleInit(): void {
    this.cfg = loadTypesenseConfig();
    if (!this.cfg.enabled) {
      return;
    }
    this.client = new Typesense.Client({
      nodes: [
        {
          host: this.cfg.host,
          port: this.cfg.port,
          protocol: this.cfg.protocol,
        },
      ],
      apiKey: this.cfg.apiKey,
      connectionTimeoutSeconds: this.cfg.connectionTimeoutSeconds,
      numRetries: 1,
    });
    this.logger.log(`Typesense client configured for collection "${this.cfg.collection}"`);
  }

  isEnabled(): boolean {
    return this.cfg.enabled && this.client != null;
  }

  getConfig(): TypesenseConfig {
    return this.cfg;
  }

  getClientOrNull(): Client | null {
    return this.client;
  }
}
