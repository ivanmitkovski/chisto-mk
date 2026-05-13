/** @type {import('jest').Config} */
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  rootDir: '.',
  testMatch: ['<rootDir>/test/**/*.spec.ts', '<rootDir>/test/**/*.test.ts'],
  moduleFileExtensions: ['js', 'json', 'ts'],
  modulePathIgnorePatterns: ['<rootDir>/dist/'],
  collectCoverageFrom: [
    'src/**/*.ts',
    '!src/**/*.spec.ts',
    '!src/**/*.module.ts',
    '!src/main.ts',
  ],
  coveragePathIgnorePatterns: [
    '<rootDir>/src/prisma-client/',
    '<rootDir>/src/generated/',
  ],
  coverageDirectory: './coverage',
  coverageThreshold: {
    global: {
      statements: 54,
      branches: 36,
      functions: 39,
      lines: 54,
    },
  },
  verbose: true,
};
