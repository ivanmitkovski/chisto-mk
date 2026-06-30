jest.mock(
  'otplib',
  () => ({
    __esModule: true,
    verify: jest.fn(() => true),
  }),
  { virtual: false },
);
