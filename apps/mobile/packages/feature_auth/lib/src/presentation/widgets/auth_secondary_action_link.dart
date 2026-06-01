import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Muted prompt on one line, accent action link on the next (auth footers).
class AuthSecondaryActionLink extends StatelessWidget {
  const AuthSecondaryActionLink({
    super.key,
    required this.prompt,
    required this.linkLabel,
    required this.onTap,
    this.semanticsKey,
  });

  final String prompt;
  final String linkLabel;
  final VoidCallback onTap;
  final Key? semanticsKey;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        button: true,
        label: '$prompt $linkLabel',
        child: GestureDetector(
          key: semanticsKey,
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  prompt,
                  textAlign: TextAlign.center,
                  style: AppTypography.authSecondaryMuted(
                    Theme.of(context).textTheme,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  linkLabel,
                  textAlign: TextAlign.center,
                  style: AppTypography.authSecondaryEmphasis(
                    Theme.of(context).textTheme,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
