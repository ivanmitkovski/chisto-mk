import type { components, paths } from '@chisto/api-client';

export type ApiComponents = components;
export type ApiPaths = paths;
export type ApiSchemas = components['schemas'];
export type SchemaName = keyof ApiSchemas;
export type Schema<T extends SchemaName> = ApiSchemas[T];

type HttpMethod = 'get' | 'post' | 'put' | 'patch' | 'delete';

type MethodDef<Path extends keyof paths, Method extends HttpMethod> = Method extends keyof paths[Path]
  ? paths[Path][Method]
  : never;

type SuccessJsonContent<Op> = Op extends {
  responses: {
    200: { content: { 'application/json': infer T } };
  };
}
  ? T
  : Op extends {
        responses: {
          201: { content: { 'application/json': infer T } };
        };
      }
    ? T
    : Op extends {
          responses: {
            204: Record<string, never>;
          };
        }
      ? void
      : unknown;

export type ResponseOf<Path extends keyof paths, Method extends HttpMethod> = SuccessJsonContent<
  MethodDef<Path, Method>
>;

export type RequestBodyOf<Path extends keyof paths, Method extends HttpMethod> = MethodDef<
  Path,
  Method
> extends {
  requestBody: { content: { 'application/json': infer T } };
}
  ? T
  : never;

export type QueryParamsOf<Path extends keyof paths, Method extends HttpMethod> = MethodDef<
  Path,
  Method
> extends {
  parameters: { query?: infer Q };
}
  ? Q
  : never;
