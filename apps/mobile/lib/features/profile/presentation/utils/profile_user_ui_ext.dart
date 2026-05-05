import 'package:flutter/material.dart';

import 'package:chisto_mobile/features/profile/domain/models/profile_user.dart';

/// UI helpers for [ProfileUser] (keeps domain model free of Flutter types).
extension ProfileUserUi on ProfileUser {
  Color get avatarColor => Color(avatarColorValue);
}
