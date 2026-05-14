import 'package:flutter/material.dart';

/// [GlobalKey]s for coach spotlight targets on the signed-in home shell.
final class HomeShellCoachKeys {
  HomeShellCoachKeys()
    : navItemKeys = List<GlobalKey>.generate(4, (_) => GlobalKey());

  final GlobalKey fabKey = GlobalKey();
  final List<GlobalKey> navItemKeys;
  final GlobalKey profileAvatarKey = GlobalKey();
}
