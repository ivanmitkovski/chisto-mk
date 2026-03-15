import 'package:flutter/foundation.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unknown;
  String? _userId;
  String? _displayName;
  String? _accessToken;

  AuthStatus get status => _status;
  String? get userId => _userId;
  String? get displayName => _displayName;
  String? get accessToken => _accessToken;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  void setAuthenticated({
    required String userId,
    required String displayName,
    String? accessToken,
  }) {
    _status = AuthStatus.authenticated;
    _userId = userId;
    _displayName = displayName;
    _accessToken = accessToken;
    notifyListeners();
  }

  void setUnauthenticated() {
    _status = AuthStatus.unauthenticated;
    _userId = null;
    _displayName = null;
    _accessToken = null;
    notifyListeners();
  }

  void updateDisplayName(String name) {
    _displayName = name;
    notifyListeners();
  }
}
