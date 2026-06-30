import tseslint from 'typescript-eslint';
import globals from 'globals';

const ignoreConfig = {
  ignores: [
    '**/node_modules/**',
    '**/dist/**',
    '**/coverage/**',
    '**/src/generated/**',
    '**/src/prisma-client/**',
  ],
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
  rules: {
    '@typescript-eslint/no-unused-vars': [
      'error',
      {
        argsIgnorePattern: '^_',
        varsIgnorePattern: '^_',
        caughtErrorsIgnorePattern: '^_',
      },
    ],
  },
};

const godFileLineBudget = {
  files: ['src/**/*.service.ts', 'src/**/*.controller.ts'],
  rules: {
    'max-lines': [
      'warn',
      {
        max: 300,
        skipBlankLines: true,
        skipComments: true,
      },
    ],
  },
};

const testRelaxed = {
  files: ['test/**/*.ts'],
  rules: {
    '@typescript-eslint/no-explicit-any': 'off',
  },
};

export default [ignoreConfig, baseConfig, ...(tseslint.configs?.recommended ?? []), godFileLineBudget, testRelaxed];
