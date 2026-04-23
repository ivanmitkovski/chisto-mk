import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Tokens use platform secure storage with Apple keychain accessibility that
/// avoids background access before first unlock; Android uses the package
/// default AES-GCM + KeyStore (see [AndroidOptions]).
class SecureTokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? _defaultStorage;

  static final FlutterSecureStorage _defaultStorage = FlutterSecureStorage(
    aOptions: const AndroidOptions(),
    iOptions: const IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    mOptions: const MacOsOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  final FlutterSecureStorage _storage;

  static const String _keyAccessToken = 'chisto_access_token';
  static const String _keyRefreshToken = 'chisto_refresh_token';
  static const String _keyUserId = 'chisto_user_id';
  static const String _keyDisplayName = 'chisto_display_name';
  static const String _keyPhoneNumber = 'chisto_phone_number';
  static const String _keyOrganizerCertifiedAt = 'chisto_organizer_certified_at';

  Future<String?> get accessToken => _storage.read(key: _keyAccessToken);
  Future<String?> get refreshToken => _storage.read(key: _keyRefreshToken);
  Future<String?> get userId => _storage.read(key: _keyUserId);
  Future<String?> get displayName => _storage.read(key: _keyDisplayName);
  Future<String?> get phoneNumber => _storage.read(key: _keyPhoneNumber);

  /// ISO-8601 timestamp from `/auth/me` or organizer quiz; used to hydrate
  /// certification before `/auth/me` succeeds on cold start.
  Future<String?> get organizerCertifiedAtIso =>
      _storage.read(key: _keyOrganizerCertifiedAt);

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait(<Future<void>>[
      _storage.write(key: _keyAccessToken, value: accessToken),
      _storage.write(key: _keyRefreshToken, value: refreshToken),
    ]);
  }

  Future<void> saveSessionData({
    required String userId,
    required String displayName,
    String? phoneNumber,
  }) async {
    final List<Future<void>> writes = <Future<void>>[
      _storage.write(key: _keyUserId, value: userId),
      _storage.write(key: _keyDisplayName, value: displayName),
    ];
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      writes.add(_storage.write(key: _keyPhoneNumber, value: phoneNumber));
    }
    await Future.wait(writes);
  }

  /// Persists or clears organizer certification time (mirrors server field).
  Future<void> writeOrganizerCertifiedAt(DateTime? at) async {
    if (at == null) {
      await _storage.delete(key: _keyOrganizerCertifiedAt);
      return;
    }
    await _storage.write(
      key: _keyOrganizerCertifiedAt,
      value: at.toUtc().toIso8601String(),
    );
  }

  Future<void> clearTokens() async {
    await Future.wait(<Future<void>>[
      _storage.delete(key: _keyAccessToken),
      _storage.delete(key: _keyRefreshToken),
      _storage.delete(key: _keyUserId),
      _storage.delete(key: _keyDisplayName),
      _storage.delete(key: _keyPhoneNumber),
      _storage.delete(key: _keyOrganizerCertifiedAt),
    ]);
  }
}
