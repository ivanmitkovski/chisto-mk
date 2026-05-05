import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';

/// Name, read-only email, phone, and limits notice for profile general info.
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radius18),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppColors.divider.withValues(alpha: 0.9),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              context.l10n.profileGeneralNameLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            RepaintBoundary(
              key: nameFieldKey,
              child: TextField(
                controller: nameController,
                focusNode: nameFocus,
                textInputAction: TextInputAction.next,
                style: fieldValueStyle,
                onSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(phoneFocus),
                decoration: inputDecoration(
                  context.l10n.profileGeneralNameHint,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.l10n.profileEmailLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
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
                  border: Border.all(
                    color: AppColors.inputBorder,
                    width: 1,
                  ),
                ),
                child: Text(
                  email.isEmpty
                      ? context.l10n.profileGeneralEmptyValue
                      : email,
                  style: fieldValueStyle,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              context.l10n.profileEmailReadOnlyHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.l10n.profileGeneralMobileLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            RepaintBoundary(
              key: phoneFieldKey,
              child: TextField(
                controller: phoneController,
                focusNode: phoneFocus,
                readOnly: true,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                style: fieldValueStyle,
                decoration: inputDecoration(
                  context.l10n.profileGeneralPhonePlaceholder,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(AppSpacing.radius14),
                border: Border.all(
                  color: AppColors.divider.withValues(alpha: 0.9),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(
                    Icons.info_outline_rounded,
                    size: AppSpacing.iconMd,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      context.l10n.profileGeneralLimitsNotice,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                            height: 1.35,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
