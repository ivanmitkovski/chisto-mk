import { of } from 'rxjs';
import { MapHttpTracingInterceptor } from '../../src/observability/map-http-tracing.interceptor';

describe('MapHttpTracingInterceptor', () => {
  it('sets traceparent header and completes', (done) => {
    const interceptor = new MapHttpTracingInterceptor();
    const headers = new Map<string, string>();
    const req = {
      method: 'GET',
      path: '/sites/map',
      url: '/sites/map',
      originalUrl: '/sites/map?zoom=11',
      query: { zoom: '11' },
      route: { path: '/sites/map' },
    };
    const res = {
      statusCode: 200,
      setHeader: (k: string, v: string) => headers.set(k, v),
    };
    const context = {
      switchToHttp: () => ({
        getRequest: () => req,
        getResponse: () => res,
      }),
    } as never;

    interceptor.intercept(context, { handle: () => of({ ok: true }) } as never).subscribe({
      complete: () => {
        expect(headers.has('traceparent')).toBe(true);
        done();
      },
    });
  });
});
