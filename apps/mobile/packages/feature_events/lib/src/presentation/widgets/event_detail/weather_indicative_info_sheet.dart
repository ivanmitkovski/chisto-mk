import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/app_surface/report_surface_aliases.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Bottom sheet with the Open-Meteo disclaimer (reusable from [WeatherCard] and elsewhere).
Future<void> showWeatherIndicativeInfoSheet(BuildContext context) {
  return AppBottomSheet.show<void>(
    context: context,
    backgroundColor: AppColors.transparent,
    isScrollControlled: true,
    builder: (BuildContext ctx) {
      return ReportSheetScaffold(
        title: ctx.l10n.eventsWeatherIndicativeInfoTitle,
        fitToContent: true,
        trailing: ReportCircleIconButton(
          icon: CupertinoIcons.xmark,
          semanticLabel: ctx.l10n.commonClose,
          onTap: () {
            Navigator.of(ctx).pop();
          },
        ),
        child: Text(
          ctx.l10n.eventsWeatherIndicativeNote,
          style: AppTypography.eventsBodyMuted(
            Theme.of(ctx).textTheme,
          ).copyWith(height: 1.45),
        ),
      );
    },
  );
}
