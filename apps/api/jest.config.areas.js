/** @type {import('jest').Config} */
/** Used only by scripts/check-coverage-areas.mjs — no global coverageThreshold (gates passed via CLI). */
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  rootDir: '.',
  testMatch: ['<rootDir>/test/**/*.spec.ts', '<rootDir>/test/**/*.test.ts'],
  moduleFileExtensions: ['js', 'json', 'ts'],
  modulePathIgnorePatterns: ['<rootDir>/dist/'],
  coverageDirectory: './coverage-area-runs',
  verbose: true,
};
