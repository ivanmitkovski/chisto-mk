import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/auth/presentation/constants/auth_otp_constants.dart';

const double _kAuthOtpBoxMaxWidth = 72;
const double _kAuthOtpBoxMinWidth = 44;
const double _kAuthOtpBoxHeight = 56;
const double _kAuthOtpBoxGap = AppSpacing.xs;

/// Six-digit OTP entry with visual boxes and hidden autofill field.
class AuthOtpInput extends StatelessWidget {
  const AuthOtpInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.semanticsLabel,
    required this.onChanged,
    this.enabled = true,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String semanticsLabel;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final TextScaler scaler = MediaQuery.textScalerOf(context)
        .clamp(maxScaleFactor: 1.2);

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: scaler),
      child: ListenableBuilder(
        listenable: controller,
        builder: (BuildContext context, Widget? _) {
          final String code = controller.text;
          final bool isComplete = code.trim().length == kAuthOtpLength;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: enabled ? () => focusNode.requestFocus() : null,
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final double gapTotal =
                        _kAuthOtpBoxGap * (kAuthOtpLength - 1);
                    final double boxWidth = ((constraints.maxWidth - gapTotal) /
                            kAuthOtpLength)
                        .clamp(_kAuthOtpBoxMinWidth, _kAuthOtpBoxMaxWidth);
                    final double rowWidth =
                        boxWidth * kAuthOtpLength + gapTotal;

                    return Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: rowWidth,
                        child: Row(
                          children: <Widget>[
                            for (int index = 0; index < kAuthOtpLength; index++) ...<Widget>[
                              if (index > 0)
                                const SizedBox(width: _kAuthOtpBoxGap),
                              _AuthOtpDigitBox(
                                width: boxWidth,
                                value: index < code.length ? code[index] : '',
                                isActive: enabled &&
                                    index == code.length &&
                                    !isComplete,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(
                height: 0,
                width: 0,
                child: Semantics(
                  label: semanticsLabel,
                  textField: true,
                  enabled: enabled,
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    enabled: enabled,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    autofillHints: const <String>[AutofillHints.oneTimeCode],
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(kAuthOtpLength),
                    ],
                    onChanged: onChanged,
                  ),
                ),
              ),
            ],
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
  });

  final double width;
  final String value;
  final bool isActive;

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
          color: hasValue
              ? AppColors.primaryDark
              : (isActive ? AppColors.primary : AppColors.inputBorder),
          width: hasValue || isActive ? 1.6 : 1.0,
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
