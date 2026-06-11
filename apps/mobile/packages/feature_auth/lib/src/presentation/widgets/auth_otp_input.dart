import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:feature_auth/src/presentation/constants/auth_otp_constants.dart';
import 'package:feature_auth/src/presentation/utils/otp_focus_helper.dart';
import 'package:flutter/material.dart';

const double _kAuthOtpBoxMaxWidth = 72;
const double _kAuthOtpBoxMinWidth = 44;
const double _kAuthOtpBoxHeight = 56;
const double _kAuthOtpBoxGap = AppSpacing.xs;

/// Six-digit OTP entry with visual boxes and an invisible overlay field.
class AuthOtpInput extends StatefulWidget {
  const AuthOtpInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.semanticsLabel,
    required this.onChanged,
    this.enabled = true,
    this.errorText,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String semanticsLabel;
  final ValueChanged<String> onChanged;
  final bool enabled;
  final String? errorText;

  @override
  State<AuthOtpInput> createState() => _AuthOtpInputState();
}

class _AuthOtpInputState extends State<AuthOtpInput> {
  Future<void> _handleOtpTap() async {
    if (!widget.enabled) return;
    await ensureOtpKeyboardVisible(widget.focusNode);
  }

  @override
  Widget build(BuildContext context) {
    final TextScaler scaler = MediaQuery.textScalerOf(
      context,
    ).clamp(maxScaleFactor: 1.2);

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: scaler),
      child: ListenableBuilder(
        listenable: widget.controller,
        builder: (BuildContext context, Widget? _) {
          final String code = widget.controller.text;
          final bool isComplete = code.trim().length == kAuthOtpLength;
          final bool hasError =
              widget.errorText != null && widget.errorText!.isNotEmpty;

          return Semantics(
            label: widget.semanticsLabel,
            hint: hasError ? widget.errorText : null,
            value: code,
            textField: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    const double gapTotal =
                        _kAuthOtpBoxGap * (kAuthOtpLength - 1);
                    final double boxWidth =
                        ((constraints.maxWidth - gapTotal) / kAuthOtpLength)
                            .clamp(_kAuthOtpBoxMinWidth, _kAuthOtpBoxMaxWidth);
                    final double rowWidth =
                        boxWidth * kAuthOtpLength + gapTotal;

                    return Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: rowWidth,
                        height: _kAuthOtpBoxHeight,
                        child: Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            IgnorePointer(
                              child: Row(
                                children: <Widget>[
                                  for (
                                    int index = 0;
                                    index < kAuthOtpLength;
                                    index++
                                  ) ...<Widget>[
                                    if (index > 0)
                                      const SizedBox(width: _kAuthOtpBoxGap),
                                    _AuthOtpDigitBox(
                                      width: boxWidth,
                                      value: index < code.length
                                          ? code[index]
                                          : '',
                                      isActive:
                                          widget.enabled &&
                                          index == code.length &&
                                          !isComplete,
                                      hasError: hasError,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Opacity(
                              opacity: 0,
                              child: AuthOtpHiddenField(
                                controller: widget.controller,
                                focusNode: widget.focusNode,
                                maxLength: kAuthOtpLength,
                                enabled: widget.enabled,
                                semanticsLabel: widget.semanticsLabel,
                                onChanged: widget.onChanged,
                                width: rowWidth,
                                height: _kAuthOtpBoxHeight,
                                onTap: () => unawaited(_handleOtpTap()),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                if (hasError) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    widget.errorText!,
                    textAlign: TextAlign.center,
                    style: AppTypography.textTheme.bodySmall!.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AuthOtpDigitBox extends StatelessWidget {
  const _AuthOtpDigitBox({
    required this.width,
    required this.value,
    required this.isActive,
    this.hasError = false,
  });

  final double width;
  final String value;
  final bool isActive;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final bool hasValue = value.isNotEmpty;
    final Duration animDuration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppMotion.xFast;

    return AnimatedContainer(
      duration: animDuration,
      curve: AppMotion.emphasized,
      width: width,
      height: _kAuthOtpBoxHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.appBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(
          color: hasError
              ? AppColors.error
              : hasValue
              ? AppColors.primaryDark
              : (isActive ? AppColors.primary : AppColors.inputBorder),
          width: hasError || hasValue || isActive ? 1.6 : 1.0,
        ),
      ),
      child: Text(
        value,
        style: AppTypography.textTheme.titleMedium!.copyWith(
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
