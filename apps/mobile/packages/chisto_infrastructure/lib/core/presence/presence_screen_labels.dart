/// Maps GoRouter paths to admin-friendly screen labels for presence heartbeats.
String presenceScreenLabelForPath(String path) {
  final String normalized = path.split('?').first;
  if (normalized.startsWith('/feed')) return 'Pollution Feed';
  if (normalized.startsWith('/map')) return 'Map';
  if (normalized.startsWith('/events')) return 'Events';
  if (normalized.startsWith('/notifications')) return 'Notifications';
  if (normalized.startsWith('/profile')) return 'Profile';
  if (normalized.startsWith('/reports/new')) return 'New Report';
  if (normalized.startsWith('/reports')) return 'Reports';
  if (normalized.startsWith('/sites/')) return 'Site Detail';
  if (normalized.startsWith('/sign-in')) return 'Sign In';
  if (normalized.startsWith('/sign-up')) return 'Sign Up';
  if (normalized.startsWith('/otp')) return 'OTP Verification';
  if (normalized.startsWith('/onboarding')) return 'Onboarding';
  if (normalized.startsWith('/splash')) return 'Splash';
  return normalized.isEmpty ? 'Home' : normalized;
}
