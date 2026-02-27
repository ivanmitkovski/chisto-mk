export type AuthResponse = {
  accessToken: string;
  user: {
    id: string;
    firstName: string;
    lastName: string;
    email: string;
    phoneNumber: string;
    role: string;
    status: string;
    isPhoneVerified: boolean;
    pointsBalance: number;
  };
};

