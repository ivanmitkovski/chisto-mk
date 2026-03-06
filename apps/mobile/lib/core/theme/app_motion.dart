import 'package:flutter/material.dart';

class AppMotion {
  const AppMotion._();

  static const Duration xFast = Duration(milliseconds: 140);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 220);
  static const Duration standard = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 700);

  static const Curve emphasized = Curves.easeOutCubic;
  static const Curve standardCurve = Curves.easeOut;
  static const Curve decelerate = Curves.easeInOut;
}
