abstract class AuthRepository {
  bool get isAuthenticated;
  String? get currentUserId;
  String? get accessToken;

  Future<void> signIn({required String phone, required String otp});
  Future<void> signUp({
    required String phone,
    required String displayName,
    required String otp,
  });
  Future<void> requestOtp(String phone);
  Future<void> signOut();
  Future<void> restoreSession();
}
