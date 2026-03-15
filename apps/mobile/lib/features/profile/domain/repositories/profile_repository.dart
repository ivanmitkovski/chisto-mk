import 'package:flutter/foundation.dart';

abstract class ProfileRepository implements Listenable {
  String get displayName;
  String get email;
  String? get avatarUrl;
  int get totalPoints;
  int get rank;

  Future<void> loadProfile();
  Future<void> updateDisplayName(String name);
  Future<void> updateAvatar(String path);
}
