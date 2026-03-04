import 'package:flutter/material.dart';

class AuthTopBar extends StatelessWidget {
  const AuthTopBar({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.85),
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
