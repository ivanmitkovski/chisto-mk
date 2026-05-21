export type RegisterResponse = {
  userId: string;
  phoneNumber: string;
  requiresPhoneVerification: true;
  otpExpiresIn: number;
};
