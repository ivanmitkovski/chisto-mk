import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

/// Bottom sheet with the Open-Meteo disclaimer (reusable from [WeatherCard] and elsewhere).
Future<void> showWeatherIndicativeInfoSheet(BuildContext context) {
  AppHaptics.tap();
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (BuildContext ctx) {
      return ReportSheetScaffold(
        title: ctx.l10n.eventsWeatherIndicativeInfoTitle,
        fitToContent: true,
        trailing: ReportCircleIconButton(
          icon: CupertinoIcons.xmark,
          semanticLabel: ctx.l10n.commonClose,
          onTap: () {
            AppHaptics.tap();
            Navigator.of(ctx).pop();
          },
        ),
        child: Text(
          ctx.l10n.eventsWeatherIndicativeNote,
          style: AppTypography.textTheme.bodyMedium?.copyWith(
            color: AppColors.textMuted,
            height: 1.45,
          ),
        ),
      );
    },
  );
}
