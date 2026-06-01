import 'package:chisto_infrastructure/shared/widgets/atoms/app_button.dart';
import 'package:flutter/material.dart';

class ReportSubmittedDialogActionButton extends StatelessWidget {
  const ReportSubmittedDialogActionButton({
    super.key,
    required this.label,
    required this.primary,
    required this.onPressed,
    this.outlined = false,
  });

  final String label;
  final bool primary;
  final bool outlined;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: outlined
          ? AppButton.outlined(label: label, onPressed: onPressed, expand: true)
          : primary
          ? AppButton.primary(label: label, onPressed: onPressed, expand: true)
          : AppButton.text(label: label, onPressed: onPressed, expand: true),
    );
  }
}
