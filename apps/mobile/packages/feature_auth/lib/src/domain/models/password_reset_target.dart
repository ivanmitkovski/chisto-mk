enum PasswordResetChannel { sms, email }

class PasswordResetTarget {
  const PasswordResetTarget({required this.channel, required this.value});

  final PasswordResetChannel channel;
  final String value;

  bool get isSms => channel == PasswordResetChannel.sms;
  bool get isEmail => channel == PasswordResetChannel.email;
}
