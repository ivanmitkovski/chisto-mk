import path from 'node:path';
import { loadEnvConfig } from '@next/env';
import type { NextConfig } from 'next';
import bundleAnalyzer from '@next/bundle-analyzer';
import createNextIntlPlugin from 'next-intl/plugin';

// Inherit shared API URL (and other vars) from the monorepo root `.env` when admin-local env is unset.
loadEnvConfig(path.resolve(__dirname, '../..'));

const withNextIntl = createNextIntlPlugin('./src/i18n/request.ts');

const withBundleAnalyzer = bundleAnalyzer({
  enabled: process.env.ANALYZE === 'true',
});

if (process.env.VERCEL === '1' && !process.env.NEXT_PUBLIC_API_BASE_URL?.trim()) {
  throw new Error(
    'NEXT_PUBLIC_API_BASE_URL is required for Vercel deployment. Set it in your Vercel project settings.',
  );
}

if (
  process.env.VERCEL === '1' &&
  process.env.NODE_ENV === 'production' &&
  !process.env.SERVER_API_BASE_URL?.trim() &&
  !process.env.API_BASE_URL?.trim()
) {
  console.warn(
    '[admin] SERVER_API_BASE_URL is unset on Vercel. BFF routes (auth refresh, proxy) rely on the build-time NEXT_PUBLIC_API_BASE_URL. Set SERVER_API_BASE_URL=https://api.chisto.mk for runtime-safe server/Edge fetches.',
  );
}

const S3_MEDIA_HOST = process.env.NEXT_PUBLIC_S3_MEDIA_HOST ?? 'chisto-dev-media.s3.eu-central-1.amazonaws.com';
const S3_MEDIA_HOSTS = Array.from(
  new Set([
    S3_MEDIA_HOST,
    'chisto-dev-media.s3.eu-central-1.amazonaws.com',
    'chisto-prod-media.s3.eu-central-1.amazonaws.com',
  ]),
);
const isProduction = process.env.NODE_ENV === 'production';

const securityHeaders = [
  { key: 'X-Content-Type-Options', value: 'nosniff' },
  { key: 'X-Frame-Options', value: 'DENY' },
  { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
  {
    key: 'Permissions-Policy',
    value: 'camera=(), microphone=(), geolocation=()',
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
  transpilePackages: ['@chisto/news-content'],
  experimental: {
    optimizePackageImports: ['lucide-react', 'recharts', 'framer-motion'],
  },
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

const exportedConfig: NextConfig = withNextIntl(withBundleAnalyzer(nextConfig));
export default exportedConfig;
