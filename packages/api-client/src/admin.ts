import { ApiClient, type ApiClientOptions } from './client';

export type AdminOverview = Record<string, unknown>;

export class AdminApiClient {
  private readonly client: ApiClient;

  constructor(options: ApiClientOptions) {
    this.client = new ApiClient(options);
  }

  async getOverview(): Promise<AdminOverview> {
    const res = await this.client.request('/admin/overview', 'get');
    if (!res.ok) throw new Error(`admin/overview ${res.status}`);
    return res.json() as Promise<AdminOverview>;
  }
}
