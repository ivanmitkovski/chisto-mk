import 'package:flutter/foundation.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unknown;
  String? _userId;
  String? _displayName;
  String? _phoneNumber;
  String? _accessToken;
  DateTime? _organizerCertifiedAt;

  AuthStatus get status => _status;
  String? get userId => _userId;
  String? get displayName => _displayName;
  String? get phoneNumber => _phoneNumber;
  String? get accessToken => _accessToken;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  DateTime? get organizerCertifiedAt => _organizerCertifiedAt;
  bool get isOrganizerCertified => _organizerCertifiedAt != null;

  void setAuthenticated({
    required String userId,
    required String displayName,
    String? accessToken,
    String? phoneNumber,
    DateTime? organizerCertifiedAt,
    /// When true, [organizerCertifiedAt] overwrites the cached value (including `null`).
    /// Use for `/auth/me` and login payloads so certification state matches the server.
    bool syncOrganizerCertifiedAt = false,
  }) {
    _status = AuthStatus.authenticated;
    _userId = userId;
    _displayName = displayName;
    _phoneNumber = phoneNumber;
    _accessToken = accessToken;
    if (syncOrganizerCertifiedAt) {
      _organizerCertifiedAt = organizerCertifiedAt;
    } else if (organizerCertifiedAt != null) {
      _organizerCertifiedAt = organizerCertifiedAt;
    }
    notifyListeners();
  }

  void setUnauthenticated() {
    _status = AuthStatus.unauthenticated;
    _userId = null;
    _displayName = null;
    _phoneNumber = null;
    _accessToken = null;
    _organizerCertifiedAt = null;
    notifyListeners();
  }

  void updateDisplayName(String name) {
    _displayName = name;
    notifyListeners();
  }

  void markOrganizerCertified(DateTime at) {
    _organizerCertifiedAt = at;
    notifyListeners();
  }
}
