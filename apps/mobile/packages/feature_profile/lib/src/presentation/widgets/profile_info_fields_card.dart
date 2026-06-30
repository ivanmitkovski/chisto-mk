import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Name, read-only email, phone, and contact-support hint for profile general info.
class ProfileInfoFieldsCard extends StatelessWidget {
  const ProfileInfoFieldsCard({
    super.key,
    required this.nameController,
    required this.phoneController,
    required this.nameFocus,
    required this.phoneFocus,
    required this.nameFieldKey,
    required this.phoneFieldKey,
    required this.email,
    required this.fieldValueStyle,
    required this.inputDecoration,
    this.nameErrorText,
  });

  final TextEditingController nameController;
  final TextEditingController phoneController;
  final FocusNode nameFocus;
  final FocusNode phoneFocus;
  final GlobalKey nameFieldKey;
  final GlobalKey phoneFieldKey;
  final String email;
  final TextStyle fieldValueStyle;
  final InputDecoration Function(String hint) inputDecoration;
  final String? nameErrorText;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radius18),
        boxShadow: AppShadows.panel(Theme.of(context).colorScheme),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.9)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              context.l10n.profileGeneralNameLabel,
              style: AppTypographySurfaces.profileFormFieldLabel(
                Theme.of(context).textTheme,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            RepaintBoundary(
              key: nameFieldKey,
              child: AppTextField(
                controller: nameController,
                focusNode: nameFocus,
                textInputAction: TextInputAction.next,
                hintText: context.l10n.profileGeneralNameHint,
                errorText: nameErrorText,
                onSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(phoneFocus),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.l10n.profileEmailLabel,
              style: AppTypographySurfaces.profileFormFieldLabel(
                Theme.of(context).textTheme,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Semantics(
              readOnly: true,
              label: context.l10n.profileEmailLabel,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(AppSpacing.radius18),
                  border: Border.all(color: AppColors.inputBorder, width: 1),
                ),
                child: Text(
                  email.isEmpty ? context.l10n.profileGeneralEmptyValue : email,
                  style: fieldValueStyle,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.l10n.profileGeneralMobileLabel,
              style: AppTypographySurfaces.profileFormFieldLabel(
                Theme.of(context).textTheme,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            RepaintBoundary(
              key: phoneFieldKey,
              child: AppTextField(
                controller: phoneController,
                focusNode: phoneFocus,
                readOnly: true,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                hintText: context.l10n.profileGeneralPhonePlaceholder,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              context.l10n.profileGeneralLimitsNotice,
              style: AppTypographySurfaces.profileFormFieldHint(
                Theme.of(context).textTheme,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
