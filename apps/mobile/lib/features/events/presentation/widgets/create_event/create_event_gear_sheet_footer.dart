import 'package:chisto_mobile/shared/widgets/atoms/app_button.dart';
import 'package:flutter/material.dart';


/// Footer CTA for the create/edit event gear picker modal.
class CreateEventGearSheetFooter extends StatelessWidget {
  const CreateEventGearSheetFooter({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: AppButton.primary(
        label: label,
        onPressed: onPressed,
        expand: true,
      ),
    );
  }
}
