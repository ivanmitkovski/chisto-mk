import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/domain/models/check_in_payload.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// High-contrast, rounded QR for organizer check-in (dense v2 payloads need size + quiet zone).
class EventCheckInQrCard extends StatelessWidget {
  const EventCheckInQrCard({
    super.key,
    required this.payload,
    required this.qrSize,
    required this.semanticsLabel,
    required this.encodeErrorDescription,
    required this.retryLabel,
    required this.onRetryAfterEncodeError,
  });

  final CheckInQrPayload payload;
  final double qrSize;
  final String semanticsLabel;
  final String encodeErrorDescription;
  final String retryLabel;
  final VoidCallback onRetryAfterEncodeError;

  @override
  Widget build(BuildContext context) {
    final String data = payload.encode();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: QrImageView(
        data: data,
        version: QrVersions.auto,
        size: qrSize,
        padding: const EdgeInsets.all(8),
        backgroundColor: AppColors.white,
        gapless: true,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.circle,
          color: AppColors.black,
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.circle,
          color: AppColors.black,
        ),
        semanticsLabel: semanticsLabel,
        errorStateBuilder: (BuildContext context, Object? error) {
          return SizedBox(
            width: qrSize,
            height: qrSize,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    encodeErrorDescription,
                    textAlign: TextAlign.center,
                    style: AppTypography.eventsGridPropertyValue(
                      Theme.of(context).textTheme,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: onRetryAfterEncodeError,
                    child: Text(retryLabel),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
