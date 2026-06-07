import path from 'node:path';
import { defineConfig } from 'vitest/config';

export default defineConfig({
  esbuild: {
    jsxInject: `import React from 'react'`,
  },
  test: {
    environment: 'node',
    environmentMatchGlobs: [['**/*.test.tsx', 'jsdom']],
    globals: false,
    include: ['src/**/*.test.ts', 'src/**/*.test.tsx'],
    setupFiles: ['./src/test/vitest-setup.ts'],
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, 'src'),
      'server-only': path.resolve(__dirname, 'src/test/server-only-stub.ts'),
    },
  },
});
