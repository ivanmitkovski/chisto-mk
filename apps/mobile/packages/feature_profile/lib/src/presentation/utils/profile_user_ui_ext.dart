import 'package:feature_profile/src/domain/models/profile_user.dart';
import 'package:flutter/material.dart';

/// UI helpers for [ProfileUser] (keeps domain model free of Flutter types).
extension ProfileUserUi on ProfileUser {
  Color get avatarColor => Color(avatarColorValue);
}
