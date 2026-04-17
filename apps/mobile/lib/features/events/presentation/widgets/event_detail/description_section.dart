import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/detail_section_header.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

class DescriptionSection extends StatefulWidget {
  const DescriptionSection({super.key, required this.event});

  final EcoEvent event;

  @override
  State<DescriptionSection> createState() => _DescriptionSectionState();
}

class _DescriptionSectionState extends State<DescriptionSection> {
  static const int _collapsedMaxLines = 5;
  bool _expanded = false;
  bool _needsExpansion = false;

  // Cache the last width used to avoid redundant TextPainter runs.
  double? _lastMeasuredWidth;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Actual width is resolved in build via LayoutBuilder; trigger a
    // re-measure by clearing the cached width on dependency change (font scale,
    // locale, etc.).
    _lastMeasuredWidth = null;
  }

  void _checkOverflow(double availableWidth) {
    if (_lastMeasuredWidth == availableWidth) {
      return;
    }
    _lastMeasuredWidth = availableWidth;

    final TextStyle style = AppTypography.eventsBodyProseRelaxed(
      Theme.of(context).textTheme,
    );
    final TextPainter tp = TextPainter(
      text: TextSpan(text: widget.event.description, style: style),
      maxLines: _collapsedMaxLines,
      // Respect the app's text direction (RTL locale support).
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: availableWidth);

    final bool overflows = tp.didExceedMaxLines;
    if (overflows != _needsExpansion) {
      setState(() => _needsExpansion = overflows);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DetailSectionHeader(context.l10n.eventsDescriptionTitle),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            // Use exact available width — no MediaQuery arithmetic guessing.
            _checkOverflow(constraints.maxWidth);

            final bool reduceMotion = MediaQuery.disableAnimationsOf(context);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                AnimatedCrossFade(
                  duration: reduceMotion ? Duration.zero : AppMotion.fast,
                  crossFadeState:
                      _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  firstChild: Text(
                    widget.event.description,
                    maxLines: _collapsedMaxLines,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.eventsBodyProseRelaxed(
                      Theme.of(context).textTheme,
                    ),
                  ),
                  secondChild: Text(
                    widget.event.description,
                    style: AppTypography.eventsBodyProseRelaxed(
                      Theme.of(context).textTheme,
                    ),
                  ),
                ),
                if (_needsExpansion)
                  CupertinoButton(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    minimumSize: Size.zero,
                    onPressed: () {
                      AppHaptics.light();
                      setState(() => _expanded = !_expanded);
                    },
                    child: Text(
                      _expanded
                          ? context.l10n.eventsDescriptionShowLess
                          : context.l10n.eventsDescriptionReadMore,
                      style: AppTypography.eventsCaptionStrong(
                        Theme.of(context).textTheme,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
