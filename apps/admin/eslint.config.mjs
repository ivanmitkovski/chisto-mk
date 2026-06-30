import js from '@eslint/js';
import tseslint from 'typescript-eslint';
import react from 'eslint-plugin-react';
import next from '@next/eslint-plugin-next';
import globals from 'globals';

const ignoreConfig = {
  ignores: ['**/node_modules/**', '**/.next/**', '**/dist/**', 'next-env.d.ts'],
};

const baseConfig = {
  files: ['**/*.{js,mjs,cjs,ts,tsx,jsx}'],
  languageOptions: {
    ecmaVersion: 'latest',
    sourceType: 'module',
    globals: {
      ...globals.browser,
      ...globals.node,
    },
  },
  settings: {
    react: {
      version: 'detect',
    },
  },
};

const extraConfigs = [
  js.configs.recommended,
  ...(tseslint.configs?.recommended ?? []),
  react.configs?.flat?.recommended ?? react.configs?.recommended,
  react.configs?.flat?.['jsx-runtime'],
  next.configs?.['flat/core-web-vitals'] ??
    next.configs?.['core-web-vitals'] ??
    next.configs?.recommended,
].filter(Boolean);

export default [ignoreConfig, baseConfig, ...extraConfigs];