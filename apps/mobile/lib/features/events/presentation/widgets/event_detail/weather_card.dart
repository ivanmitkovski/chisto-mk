import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/data/weather_repository.dart';
import 'package:chisto_mobile/features/events/data/weather_wmo.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/detail_section_header.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/event_detail_surface_decoration.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/weather_indicative_info_sheet.dart';

/// Weather forecast card shown in the event detail screen.
///
/// Only rendered when [event.siteLat] and [event.siteLng] are non-null.
/// Fetches from Open-Meteo (forecast + archive for past days) and caches per
/// (lat, lng, date). Shows a retry affordance if loading fails — non-critical UI.
class WeatherCard extends StatefulWidget {
  const WeatherCard({super.key, required this.event});

  final EcoEvent event;

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> {
  DayWeather? _weather;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_fetch());
  }

  Future<void> _fetch() async {
    final double? lat = widget.event.siteLat;
    final double? lng = widget.event.siteLng;
    if (lat == null || lng == null) {
      setState(() {
        _loading = false;
        _failed = true;
      });
      return;
    }
    final DayWeather? result = await WeatherRepository.instance.fetchForDate(
      lat: lat,
      lng: lng,
      targetDate: widget.event.date,
      scheduledAtUtc: widget.event.scheduledAtUtc,
    );
    if (!mounted) return;
    setState(() {
      _weather = result;
      _loading = false;
      _failed = result == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DetailSectionHeader(context.l10n.eventsWeatherForecast),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: EventDetailSurfaceDecoration.detailModule(),
          child: _loading
              ? _buildSkeleton(context)
              : _failed
                  ? _buildErrorState(context)
                  : _buildContent(context, _weather!),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Icon(
              CupertinoIcons.cloud_bolt_rain,
              size: 28,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                context.l10n.eventsWeatherUnavailableBody,
                style: AppTypography.eventsBodyProse(
                  Theme.of(context).textTheme,
                ).copyWith(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(
            onPressed: () {
              setState(() {
                _loading = true;
                _failed = false;
              });
              unawaited(_fetch());
            },
            child: Text(context.l10n.eventsWeatherRetry),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                height: 14,
                width: 100,
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 11,
                width: 140,
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
        _weatherInfoIconButton(context),
      ],
    );
  }

  Widget _buildContent(BuildContext context, DayWeather w) {
    final WeatherWmoVisual visual = WeatherWmo.visual(w.wmoCode);
    final String description = WeatherWmo.description(w.wmoCode);
    final IconData icon = _iconFor(visual);
    final Color accent = _colorFor(visual);
    final String tempRange =
        '${w.minTempC.round()}° – ${w.maxTempC.round()}°C';
    final String precipLine = w.precipitationMm > 0.1
        ? context.l10n.eventsWeatherPrecipitationMm(
            w.precipitationMm.toStringAsFixed(1),
          )
        : context.l10n.eventsWeatherNoPrecipitation;
    final int? prob = w.precipitationProbabilityMax;
    final String? chance = prob != null && prob >= 35
        ? context.l10n.eventsWeatherPrecipChance(prob)
        : null;
    final String detail = chance != null
        ? '$tempRange · $precipLine · $chance'
        : '$tempRange · $precipLine';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(
            icon,
            size: 26,
            color: accent,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                description,
                style: AppTypography.eventsSectionTitle(
                  Theme.of(context).textTheme,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: AppTypography.eventsListCardMeta(
                  Theme.of(context).textTheme,
                ),
              ),
            ],
          ),
        ),
        _weatherInfoIconButton(context),
      ],
    );
  }

  static Widget _weatherInfoIconButton(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.eventsWeatherIndicativeInfoSemantic,
      child: IconButton(
        onPressed: () => showWeatherIndicativeInfoSheet(context),
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(
          minWidth: AppSpacing.avatarMd,
          minHeight: AppSpacing.avatarMd,
        ),
        icon: Icon(
          CupertinoIcons.info_circle,
          size: 22,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  static IconData _iconFor(WeatherWmoVisual v) {
    return switch (v) {
      WeatherWmoVisual.clear => Icons.wb_sunny,
      WeatherWmoVisual.mainlyClear => Icons.brightness_medium,
      WeatherWmoVisual.partlyCloudy => Icons.wb_cloudy,
      WeatherWmoVisual.overcast => Icons.cloud,
      WeatherWmoVisual.fog => Icons.cloud_queue,
      WeatherWmoVisual.drizzle => Icons.grain,
      WeatherWmoVisual.rain => Icons.umbrella,
      WeatherWmoVisual.snow => Icons.ac_unit,
      WeatherWmoVisual.rainShowers => Icons.umbrella,
      WeatherWmoVisual.snowShowers => Icons.ac_unit,
      WeatherWmoVisual.thunderstorm => Icons.bolt,
    };
  }

  static Color _colorFor(WeatherWmoVisual v) {
    return switch (v) {
      WeatherWmoVisual.clear || WeatherWmoVisual.mainlyClear =>
        const Color(0xFFFFBF00),
      WeatherWmoVisual.partlyCloudy ||
      WeatherWmoVisual.overcast ||
      WeatherWmoVisual.fog =>
        const Color(0xFF8099B0),
      WeatherWmoVisual.snow || WeatherWmoVisual.snowShowers =>
        const Color(0xFF64B5F6),
      WeatherWmoVisual.thunderstorm => const Color(0xFFFFA000),
      WeatherWmoVisual.drizzle ||
      WeatherWmoVisual.rain ||
      WeatherWmoVisual.rainShowers =>
        const Color(0xFF3BA3F7),
    };
  }
}
