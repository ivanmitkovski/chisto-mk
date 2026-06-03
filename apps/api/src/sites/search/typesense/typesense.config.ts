import { loadFeatureFlags } from '../../../config/feature-flags';

export interface TypesenseConfig {
  enabled: boolean;
  host: string;
  port: number;
  protocol: 'http' | 'https';
  apiKey: string;
  collection: string;
  connectionTimeoutSeconds: number;
}

export function loadTypesenseConfig(): TypesenseConfig {
  const flags = loadFeatureFlags();
  const host = process.env.TYPESENSE_HOST?.trim() ?? '';
  const apiKey = process.env.TYPESENSE_API_KEY?.trim() ?? '';
  const portRaw = process.env.TYPESENSE_PORT?.trim();
  const portParsed = portRaw ? Number.parseInt(portRaw, 10) : 8108;
  const port = Number.isFinite(portParsed) && portParsed > 0 ? portParsed : 8108;
  const protocolRaw = (process.env.TYPESENSE_PROTOCOL?.trim() ?? 'https').toLowerCase();
  const protocol: 'http' | 'https' = protocolRaw === 'http' ? 'http' : 'https';
  const collection = process.env.TYPESENSE_SITES_COLLECTION?.trim() || 'map_sites';
  const timeoutRaw = process.env.TYPESENSE_CONNECTION_TIMEOUT_SECONDS?.trim();
  const timeoutParsed = timeoutRaw ? Number.parseInt(timeoutRaw, 10) : 2;
  const connectionTimeoutSeconds =
    Number.isFinite(timeoutParsed) && timeoutParsed > 0 ? timeoutParsed : 2;

  const configured = host.length > 0 && apiKey.length > 0;

  return {
    enabled: flags.mapSearchTypesense && configured,
    host,
    port,
    protocol,
    apiKey,
    collection,
    connectionTimeoutSeconds,
  };
}
