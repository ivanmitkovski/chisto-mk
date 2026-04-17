import type { NextConfig } from 'next';
import bundleAnalyzer from '@next/bundle-analyzer';

const withBundleAnalyzer = bundleAnalyzer({
  enabled: process.env.ANALYZE === 'true',
});

if (process.env.VERCEL === '1' && !process.env.NEXT_PUBLIC_API_BASE_URL?.trim()) {
  throw new Error(
    'NEXT_PUBLIC_API_BASE_URL is required for Vercel deployment. Set it in your Vercel project settings.',
  );
}

const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:3000';
const S3_MEDIA_HOST = process.env.NEXT_PUBLIC_S3_MEDIA_HOST ?? 'chisto-dev-media.s3.eu-central-1.amazonaws.com';
const S3_MEDIA_HOSTS = Array.from(
  new Set([
    S3_MEDIA_HOST,
    'chisto-dev-media.s3.eu-central-1.amazonaws.com',
    'chisto-prod-media.s3.eu-central-1.amazonaws.com',
  ]),
);
const isProduction = process.env.NODE_ENV === 'production';

/** Carto basemap tiles (Leaflet); explicit hosts avoid widening connect-src to untrusted origins. */
const CARTO_TILE_HOSTS = [
  'https://a.basemaps.cartocdn.com',
  'https://b.basemaps.cartocdn.com',
  'https://c.basemaps.cartocdn.com',
] as const;

const securityHeaders = [
  { key: 'X-Content-Type-Options', value: 'nosniff' },
  { key: 'X-Frame-Options', value: 'DENY' },
  { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
  {
    key: 'Permissions-Policy',
    value: 'camera=(), microphone=(), geolocation=()',
  },
  {
    key: 'Content-Security-Policy',
    value: [
      "default-src 'self'",
      "script-src 'self' 'unsafe-inline' 'unsafe-eval'",
      "style-src 'self' 'unsafe-inline'",
      "img-src 'self' data: https: blob:",
      `connect-src 'self' ${API_BASE_URL.replace(/\/$/, '')} ${CARTO_TILE_HOSTS.join(' ')}`,
      "frame-ancestors 'none'",
      "base-uri 'self'",
      "form-action 'self'",
    ].join('; '),
  },
  ...(isProduction
    ? [
        {
          key: 'Strict-Transport-Security',
          value: 'max-age=31536000; includeSubDomains; preload',
        },
      ]
    : []),
];

const nextConfig: NextConfig = {
  reactStrictMode: true,
  images: {
    remotePatterns: S3_MEDIA_HOSTS.map((hostname) => ({
      protocol: 'https',
      hostname,
      pathname: '/**',
    })),
  },
  async headers() {
    return [
      {
        source: '/:path*',
        headers: securityHeaders,
      },
    ];
  },
};

const exportedConfig: NextConfig = withBundleAnalyzer(nextConfig);
export default exportedConfig;
