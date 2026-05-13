/** @type {import('jest').Config} */
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  rootDir: '../..',
  setupFiles: ['<rootDir>/test/e2e/jest-setup-mocks.js', '<rootDir>/test/e2e/dotenv-setup.js'],
  testMatch: ['<rootDir>/test/e2e/**/*.e2e-spec.ts'],
  moduleFileExtensions: ['js', 'json', 'ts'],
  modulePathIgnorePatterns: ['<rootDir>/dist/'],
  testTimeout: 60_000,
  maxWorkers: 1,
};
