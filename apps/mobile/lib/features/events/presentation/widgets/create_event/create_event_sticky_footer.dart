import 'package:flutter/material.dart';

import 'package:chisto_mobile/features/profile/presentation/widgets/profile_primary_action_bar.dart';
import 'package:chisto_mobile/shared/widgets/primary_button.dart';

/// Pinned bottom bar for create-event: primary CTA.
///
/// Extra bottom inset on the form sliver so the last field can scroll above the
/// sticky bar (~footer height + small buffer). Kept modest to avoid a large empty
/// band above the CTA when the form is short. The create-event scaffold uses
/// [Scaffold.resizeToAvoidBottomInset] false and [ProfilePrimaryActionBar] with
/// [ProfilePrimaryActionBar.padForKeyboard] false so the CTA stays pinned to the
/// bottom safe area (the keyboard may cover it; users scroll the form to focus).
class CreateEventStickyFooter extends StatelessWidget {
  const CreateEventStickyFooter({
    super.key,
    required this.submitting,
    required this.submitLabel,
    required this.onSubmit,
  });

  final bool submitting;
  final String submitLabel;
  final VoidCallback onSubmit;

  /// Extra bottom padding for [CustomScrollView] / form content.
  static const double scrollBottomReserve = 88;

  @override
  Widget build(BuildContext context) {
    return ProfilePrimaryActionBar(
      padForKeyboard: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            button: true,
            enabled: !submitting,
            label: submitLabel,
            child: PrimaryButton(
              label: submitLabel,
              enabled: !submitting,
              onPressed: onSubmit,
            ),
          ),
        ],
      ),
    );
  }
}
