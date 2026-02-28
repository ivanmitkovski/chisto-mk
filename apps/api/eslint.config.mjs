import tseslint from 'typescript-eslint';
import globals from 'globals';

const ignoreConfig = {
  ignores: ['**/node_modules/**', '**/dist/**', '**/coverage/**'],
};

const baseConfig = {
  files: ['**/*.{ts,mts,cts,js,mjs,cjs}'],
  languageOptions: {
    ecmaVersion: 'latest',
    sourceType: 'module',
    globals: {
      ...globals.node,
      ...globals.jest,
    },
  },
};

export default [ignoreConfig, baseConfig, ...(tseslint.configs?.recommended ?? [])];
