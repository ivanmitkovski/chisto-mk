import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Whether session credentials survive app termination.
enum TokenPersistenceMode {
  /// Tokens and session metadata stored in platform secure storage.
  persistent,

  /// Session credentials kept in memory only (cleared on process exit).
  ephemeral,
}

/// Tokens use platform secure storage with Apple keychain accessibility that
/// avoids background access before first unlock; Android uses the package
/// default AES-GCM + KeyStore (see [AndroidOptions]).
///
/// [deviceId] is always persisted. Other session fields follow [persistenceMode].
class SecureTokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? _defaultStorage;

  static const FlutterSecureStorage _defaultStorage = FlutterSecureStorage(
    aOptions: AndroidOptions.defaultOptions,
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    mOptions: MacOsOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  final FlutterSecureStorage _storage;
  final Map<String, String> _ephemeral = <String, String>{};

  TokenPersistenceMode _persistenceMode = TokenPersistenceMode.persistent;

  TokenPersistenceMode get persistenceMode => _persistenceMode;

  bool get isPersistent => _persistenceMode == TokenPersistenceMode.persistent;

  static const String _keyAccessToken = 'chisto_access_token';
  static const String _keyRefreshToken = 'chisto_refresh_token';
  static const String _keyUserId = 'chisto_user_id';
  static const String _keyDisplayName = 'chisto_display_name';
  static const String _keyPhoneNumber = 'chisto_phone_number';
  static const String _keyOrganizerCertifiedAt =
      'chisto_organizer_certified_at';
  static const String _keyDeviceId = 'chisto_device_id';

  static const List<String> _sessionKeys = <String>[
    _keyAccessToken,
    _keyRefreshToken,
    _keyUserId,
    _keyDisplayName,
    _keyPhoneNumber,
    _keyOrganizerCertifiedAt,
  ];

  /// Configures where new session writes go. Ephemeral mode clears on-disk session keys.
  Future<void> setPersistenceMode({required bool persistent}) async {
    if (persistent) {
      _persistenceMode = TokenPersistenceMode.persistent;
      _ephemeral.clear();
      return;
    }
    _persistenceMode = TokenPersistenceMode.ephemeral;
    _ephemeral.clear();
    await _clearPersistentSessionKeys();
  }

  Future<String?> get accessToken => _readSession(_keyAccessToken);

  Future<String?> get refreshToken => _readSession(_keyRefreshToken);

  Future<String?> get userId => _readSession(_keyUserId);

  Future<String?> get displayName => _readSession(_keyDisplayName);

  Future<String?> get phoneNumber => _readSession(_keyPhoneNumber);

  Future<String> get deviceId async {
    final String? existing = await _storage.read(key: _keyDeviceId);
    if (existing != null && existing.trim().isNotEmpty) {
      return existing.trim();
    }
    final String created = _createDeviceId();
    await _storage.write(key: _keyDeviceId, value: created);
    return created;
  }

  /// ISO-8601 timestamp from `/auth/me` or organizer quiz; used to hydrate
  /// certification before `/auth/me` succeeds on cold start.
  Future<String?> get organizerCertifiedAtIso =>
      _readSession(_keyOrganizerCertifiedAt);

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait(<Future<void>>[
      _writeSession(_keyAccessToken, accessToken),
      _writeSession(_keyRefreshToken, refreshToken),
    ]);
  }

  Future<void> saveSessionData({
    required String userId,
    required String displayName,
    String? phoneNumber,
  }) async {
    final List<Future<void>> writes = <Future<void>>[
      _writeSession(_keyUserId, userId),
      _writeSession(_keyDisplayName, displayName),
    ];
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      writes.add(_writeSession(_keyPhoneNumber, phoneNumber));
    }
    await Future.wait(writes);
  }

  /// Persists or clears organizer certification time (mirrors server field).
  Future<void> writeOrganizerCertifiedAt(DateTime? at) async {
    if (at == null) {
      await _deleteSession(_keyOrganizerCertifiedAt);
      return;
    }
    await _writeSession(
      _keyOrganizerCertifiedAt,
      at.toUtc().toIso8601String(),
    );
  }

  Future<void> clearTokens() async {
    _ephemeral.clear();
    await _clearPersistentSessionKeys();
  }

  Future<String?> _readSession(String key) async {
    if (_persistenceMode == TokenPersistenceMode.ephemeral) {
      return _ephemeral[key];
    }
    return _storage.read(key: key);
  }

  Future<void> _writeSession(String key, String value) async {
    if (_persistenceMode == TokenPersistenceMode.ephemeral) {
      _ephemeral[key] = value;
      return;
    }
    await _storage.write(key: key, value: value);
  }

  Future<void> _deleteSession(String key) async {
    _ephemeral.remove(key);
    await _storage.delete(key: key);
  }

  Future<void> _clearPersistentSessionKeys() async {
    await Future.wait(
      _sessionKeys.map((String key) => _storage.delete(key: key)),
    );
  }

  static String _createDeviceId() {
    final Random random = Random.secure();
    final List<int> bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int value) => value.toRadixString(16).padLeft(2, '0');
    final String raw = bytes.map(hex).join();
    return '${raw.substring(0, 8)}-${raw.substring(8, 12)}-${raw.substring(12, 16)}-${raw.substring(16, 20)}-${raw.substring(20)}';
  }
}
