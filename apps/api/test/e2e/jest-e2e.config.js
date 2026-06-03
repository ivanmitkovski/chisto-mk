/** @type {import('jest').Config} */
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  rootDir: '../..',
  setupFiles: ['<rootDir>/test/e2e/jest-setup-mocks.js', '<rootDir>/test/e2e/dotenv-setup.js'],
  testMatch: ['<rootDir>/test/e2e/**/*.e2e-spec.ts'],
  moduleFileExtensions: ['js', 'json', 'ts'],
  modulePathIgnorePatterns: ['<rootDir>/dist/'],
  // AWS SDK v3 uses dynamic import; Jest's VM sandbox needs these packages transformed.
  transformIgnorePatterns: ['/node_modules/(?!(@aws-sdk|@smithy)/)'],
  testTimeout: 60_000,
  maxWorkers: 1,
  forceExit: true,
  testSequencer: '<rootDir>/test/e2e/jest-e2e-sequencer.js',
};
