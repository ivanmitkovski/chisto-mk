import 'package:chisto_infrastructure/shared/widgets/atoms/primary_button.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_profile/feature_profile.dart';
import 'package:flutter/material.dart';

/// Pinned bottom bar for create-event: primary CTA via [Scaffold.bottomNavigationBar].
///
/// With [Scaffold.resizeToAvoidBottomInset] enabled, the scaffold insets the
/// layout once and this bar stays at the bottom of the viewport. The form adds
/// [scrollBottomReserve] so fields can scroll above the footer.
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

  /// Space reserved at the bottom of the form scroll for this footer
  /// (md + button + lg padding, with safe-area headroom).
  static const double scrollBottomReserve =
      AppSpacing.md + 56 + AppSpacing.lg + AppSpacing.lg;

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
