import type { paths } from './generated/schema';

export type ApiPaths = paths;

type HttpMethod = 'get' | 'post' | 'put' | 'patch' | 'delete';

export type ApiClientOptions = {
  baseUrl: string;
  getAccessToken?: () => string | undefined | Promise<string | undefined>;
  fetch?: typeof fetch;
};

export class ApiClient {
  private readonly baseUrl: string;
  private readonly getAccessToken?: ApiClientOptions['getAccessToken'];
  private readonly fetchFn: typeof fetch;

  constructor(options: ApiClientOptions) {
    this.baseUrl = options.baseUrl.replace(/\/$/, '');
    this.getAccessToken = options.getAccessToken;
    this.fetchFn = options.fetch ?? fetch;
  }

  async request<Path extends keyof paths, Method extends HttpMethod & keyof paths[Path]>(
    path: Path,
    method: Method,
    init?: RequestInit & { params?: Record<string, string> },
  ): Promise<Response> {
    let url = `${this.baseUrl}${String(path)}`;
    if (init?.params) {
      const q = new URLSearchParams(init.params);
      url += `?${q.toString()}`;
    }
    const headers = new Headers(init?.headers);
    if (!headers.has('Content-Type') && init?.body) {
      headers.set('Content-Type', 'application/json');
    }
    const token = await this.getAccessToken?.();
    if (token) {
      headers.set('Authorization', `Bearer ${token}`);
    }
    return this.fetchFn(url, { ...init, method: method.toUpperCase(), headers });
  }
}
