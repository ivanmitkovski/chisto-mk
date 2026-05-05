import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';

/// Design-system confirm dialog: [AppColors.panelBackground] card, pill buttons,
/// optional "type to confirm" gate (e.g. delete account).
class AppConfirmDialog extends StatefulWidget {
  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.confirmLabel,
    this.body,
    this.bodyWidget,
    required this.cancelLabel,
    this.isDestructive = false,
    this.typeToConfirm,
    this.typedFieldPlaceholder,
    this.typedMismatchMessage,
  });

  final String title;
  final String confirmLabel;
  final String? body;
  final Widget? bodyWidget;
  final String cancelLabel;
  final bool isDestructive;
  final String? typeToConfirm;
  final String? typedFieldPlaceholder;
  final String? typedMismatchMessage;

  /// Returns `true` if the user confirmed, `false` if cancelled, `null` if dismissed
  /// when [barrierDismissible] is true.
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String confirmLabel,
    String? body,
    Widget? bodyWidget,
    String? cancelLabel,
    bool isDestructive = false,
    bool barrierDismissible = true,
    String? typeToConfirm,
    String? typedFieldPlaceholder,
    String? typedMismatchMessage,
  }) {
    assert(
      body == null || bodyWidget == null,
      'Provide at most one of body or bodyWidget.',
    );
    assert(
      typeToConfirm == null ||
          (typedFieldPlaceholder != null && typedMismatchMessage != null),
      'typedFieldPlaceholder and typedMismatchMessage are required when '
      'typeToConfirm is set.',
    );

    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: AppColors.overlay,
      useRootNavigator: true,
      builder: (BuildContext dialogContext) {
        return AppConfirmDialog(
          title: title,
          confirmLabel: confirmLabel,
          body: body,
          bodyWidget: bodyWidget,
          cancelLabel: cancelLabel ?? dialogContext.l10n.commonCancel,
          isDestructive: isDestructive,
          typeToConfirm: typeToConfirm,
          typedFieldPlaceholder: typedFieldPlaceholder,
          typedMismatchMessage: typedMismatchMessage,
        );
      },
    );
  }

  @override
  State<AppConfirmDialog> createState() => _AppConfirmDialogState();
}

class _AppConfirmDialogState extends State<AppConfirmDialog> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _controller.addListener(() => setState(() {}));
    if (widget.typeToConfirm != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _phraseMatches =>
      widget.typeToConfirm == null ||
      _controller.text.trim() == widget.typeToConfirm;

  void _onConfirm(BuildContext dialogContext) {
    AppHaptics.tap();
    if (!_phraseMatches) {
      final String? msg = widget.typedMismatchMessage;
      if (msg != null) {
        AppSnack.show(
          dialogContext,
          message: msg,
          type: AppSnackType.warning,
        );
      }
      return;
    }
    Navigator.of(dialogContext).pop(true);
  }

  void _onCancel(BuildContext dialogContext) {
    AppHaptics.tap();
    Navigator.of(dialogContext).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final double keyboardBottom = MediaQuery.viewInsetsOf(context).bottom;

    return Dialog(
      backgroundColor: AppColors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: keyboardBottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: AppColors.panelBackground,
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            border: Border.all(
              color: AppColors.divider.withValues(alpha: 0.75),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.08),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.07),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                widget.title,
                style: AppTypography.sectionHeader.copyWith(fontSize: 19),
              ),
              if (widget.body != null) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  widget.body!,
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
              if (widget.bodyWidget != null) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                widget.bodyWidget!,
              ],
              if (widget.typeToConfirm != null) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(color: AppColors.inputBorder),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                      horizontal: AppSpacing.md,
                    ),
                    child: Text(
                      widget.typeToConfirm!,
                      textAlign: TextAlign.center,
                      style: AppTypography.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Semantics(
                  label: widget.typedFieldPlaceholder,
                  textField: true,
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    textInputAction: TextInputAction.done,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      hintText: widget.typedFieldPlaceholder,
                      filled: true,
                      fillColor: AppColors.inputFill,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusLg),
                        borderSide: const BorderSide(
                          color: AppColors.inputBorder,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusLg),
                        borderSide: const BorderSide(
                          color: AppColors.inputBorder,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusLg),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    style: AppTypography.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    onSubmitted: (_) => _onConfirm(context),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              OutlinedButton(
                onPressed: () => _onCancel(context),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  side: BorderSide(
                    color: AppColors.divider.withValues(alpha: 0.95),
                  ),
                  foregroundColor: AppColors.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                ),
                child: Text(
                  widget.cancelLabel,
                  style: AppTypography.buttonLabel.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 17,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 52,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _phraseMatches
                      ? () => _onConfirm(context)
                      : null,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: widget.isDestructive
                        ? AppColors.accentDanger
                        : AppColors.primary,
                    foregroundColor: AppColors.white,
                    disabledBackgroundColor: AppColors.inputFill,
                    disabledForegroundColor: AppColors.textMuted,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusPill),
                    ),
                  ),
                  child: Text(
                    widget.confirmLabel,
                    style: AppTypography.buttonLabel.copyWith(
                      color: AppColors.white,
                      fontSize: 17,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
